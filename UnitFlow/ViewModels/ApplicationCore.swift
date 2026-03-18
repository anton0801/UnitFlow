import Foundation
import AppsFlyerLib

final class UnitFlowApplication: ApplicationUseCase {
    
    private let storage: StoragePort
    private let validation: ValidationPort
    private let network: NetworkPort
    private let notification: NotificationPort
    private let events: EventPublisher
    
    private var phase: AppPhase = .idle
    private var config: AppConfig = .initial
    private var tracking: TrackingInfo = .empty
    private var navigation: NavigationInfo = .empty
    private var permissions: PermissionState = .initial
    
    private var isLocked = false
    private var timeoutTask: Task<Void, Never>?
    
    init(
        storage: StoragePort,
        validation: ValidationPort,
        network: NetworkPort,
        notification: NotificationPort,
        events: EventPublisher
    ) {
        self.storage = storage
        self.validation = validation
        self.network = network
        self.notification = notification
        self.events = events
    }
    
    // MARK: - Use Cases
    
    func initialize() {
        phase = .loading
        events.publish(.phaseChanged(.loading))
        
        loadConfiguration()
        scheduleTimeout()
    }
    
    func handleTracking(_ data: [String: Any]) {
        let converted = data.mapValues { "\($0)" }
        tracking = TrackingInfo(data: converted)
        storage.saveTracking(converted)
        events.publish(.trackingDataChanged(tracking))
        
        Task {
            await performValidation()
        }
    }
    
    func handleNavigation(_ data: [String: Any]) {
        let converted = data.mapValues { "\($0)" }
        navigation = NavigationInfo(data: converted)
        storage.saveNavigation(converted)
        events.publish(.navigationDataChanged(navigation))
    }
    
    func requestPermission() {
        notification.requestAuthorization { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                self.permissions = PermissionState(approved: true, declined: false, lastAsked: Date())
                self.notification.registerForRemoteNotifications()
            } else {
                self.permissions = PermissionState(approved: false, declined: true, lastAsked: Date())
            }
            
            self.storage.savePermissions(self.permissions)
            self.events.publish(.permissionStateChanged(self.permissions))
            self.events.publish(.shouldHidePermissionPrompt)
            self.events.publish(.shouldNavigateToWeb)
        }
    }
    
    func deferPermission() {
        permissions = PermissionState(approved: false, declined: false, lastAsked: Date())
        storage.savePermissions(permissions)
        events.publish(.permissionStateChanged(permissions))
        events.publish(.shouldHidePermissionPrompt)
        events.publish(.shouldNavigateToWeb)
    }
    
    func handleNetworkChange(isConnected: Bool) {
        guard !isLocked else { return }
        events.publish(.networkStatusChanged(isConnected))
    }
    
    func handleTimeout() {
        guard !isLocked else { return }
        phase = .failed
        events.publish(.phaseChanged(.failed))
        events.publish(.shouldNavigateToMain)
    }
    
    // MARK: - Private Logic
    
    private func loadConfiguration() {
        let loaded = storage.loadConfig()
        
        config = AppConfig(
            mode: loaded.mode,
            firstLaunch: loaded.firstLaunch
        )
        
        tracking = TrackingInfo(data: loaded.tracking)
        navigation = NavigationInfo(data: loaded.navigation)
        
        permissions = PermissionState(
            approved: loaded.permissions.approved,
            declined: loaded.permissions.declined,
            lastAsked: loaded.permissions.lastAsked
        )
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !isLocked else { return }
            await MainActor.run {
                self.handleTimeout()
            }
        }
    }
    
    private func performValidation() async {
        guard !isLocked, !tracking.isEmpty else { return }
        
        phase = .validating
        await MainActor.run { events.publish(.phaseChanged(.validating)) }
        
        do {
            let isValid = try await validation.validate()
            await MainActor.run {
                events.publish(.validationCompleted(isValid))
                
                if isValid {
                    phase = .validated
                    events.publish(.phaseChanged(.validated))
                    Task { await executeBusinessLogic() }
                } else {
                    phase = .failed
                    events.publish(.phaseChanged(.failed))
                    events.publish(.shouldNavigateToMain)
                }
            }
        } catch {
            await MainActor.run {
                phase = .failed
                events.publish(.phaseChanged(.failed))
                events.publish(.shouldNavigateToMain)
            }
        }
    }
    
    private func executeBusinessLogic() async {
        guard !isLocked, !tracking.isEmpty else {
            await MainActor.run { events.publish(.shouldNavigateToMain) }
            return
        }
        
        // Check temp_url shortcut
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            await MainActor.run { completeWithEndpoint(temp) }
            return
        }
        
        // Organic first launch flow
        if tracking.isOrganic && config.firstLaunch {
            await runOrganicFlow()
            return
        }
        
        // Normal flow
        await requestEndpoint()
    }
    
    private func runOrganicFlow() async {
        phase = .processing
        await MainActor.run { events.publish(.phaseChanged(.processing)) }
        
        // 5 second delay
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !isLocked else { return }
        
        do {
            let deviceID = await getDeviceID()
            var fetched = try await network.fetchAttribution(deviceID: deviceID)
            
            // Merge navigation
            for (key, value) in navigation.data {
                if fetched[key] == nil {
                    fetched[key] = value
                }
            }
            
            await MainActor.run {
                let converted = fetched.mapValues { "\($0)" }
                tracking = TrackingInfo(data: converted)
                storage.saveTracking(converted)
                events.publish(.trackingDataChanged(tracking))
            }
            
            await requestEndpoint()
        } catch {
            await MainActor.run {
                phase = .failed
                events.publish(.phaseChanged(.failed))
                events.publish(.shouldNavigateToMain)
            }
        }
    }
    
    private func requestEndpoint() async {
        guard !isLocked else { return }
        
        phase = .processing
        await MainActor.run { events.publish(.phaseChanged(.processing)) }
        
        do {
            let trackingDict = tracking.data.mapValues { $0 as Any }
            let endpoint = try await network.fetchEndpoint(tracking: trackingDict)
            
            await MainActor.run {
                completeWithEndpoint(endpoint)
            }
        } catch {
            await MainActor.run {
                phase = .failed
                events.publish(.phaseChanged(.failed))
                events.publish(.shouldNavigateToMain)
            }
        }
    }
    
    private func completeWithEndpoint(_ endpoint: String) {
        guard !isLocked else { return }
        
        timeoutTask?.cancel()
        isLocked = true
        
        config.mode = "Active"
        config.firstLaunch = false
        phase = .ready(endpoint)
        
        storage.saveEndpoint(endpoint)
        storage.saveMode("Active")
        storage.markLaunched()
        
        events.publish(.endpointReceived(endpoint))
        events.publish(.phaseChanged(.ready(endpoint)))
        
        if permissions.canAsk {
            events.publish(.shouldShowPermissionPrompt)
        } else {
            events.publish(.shouldNavigateToWeb)
        }
    }
    
    private func getDeviceID() async -> String {
        // Mock - will be injected via adapter
        return await MainActor.run {
            AppsFlyerLib.shared().getAppsFlyerUID()
        }
    }
}
