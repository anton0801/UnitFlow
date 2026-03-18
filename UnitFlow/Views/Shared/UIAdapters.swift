import SwiftUI
import Combine
import UserNotifications
import Network

final class SystemNotificationAdapter: NotificationPort {
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

@MainActor
final class UIEventPublisher: ObservableObject, EventPublisher {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    @Published var currentPhase: AppPhase = .idle
    
    func publish(_ event: DomainEvent) {
        switch event {
        case .shouldShowPermissionPrompt:
            showPermissionPrompt = true
            
        case .shouldHidePermissionPrompt:
            showPermissionPrompt = false
            
        case .shouldNavigateToMain:
            navigateToMain = true
            
        case .shouldNavigateToWeb:
            navigateToWeb = true
            
        case .phaseChanged(let phase):
            currentPhase = phase
            
        case .networkStatusChanged(let isConnected):
            showOfflineView = !isConnected
            
        default:
            break
        }
    }
}

final class NetworkMonitorAdapter {
    
    private let monitor = NWPathMonitor()
    private let useCase: ApplicationUseCase
    
    init(useCase: ApplicationUseCase) {
        self.useCase = useCase
    }
    
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.useCase.handleNetworkChange(isConnected: path.status == .satisfied)
            }
        }
        monitor.start(queue: .global(qos: .background))
    }
}
