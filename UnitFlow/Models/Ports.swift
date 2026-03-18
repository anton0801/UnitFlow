import Foundation

protocol ApplicationUseCase {
    func initialize()
    func handleTracking(_ data: [String: Any])
    func handleNavigation(_ data: [String: Any])
    func requestPermission()
    func deferPermission()
    func handleNetworkChange(isConnected: Bool)
    func handleTimeout()
}

protocol StoragePort {
    func saveTracking(_ data: [String: String])
    func saveNavigation(_ data: [String: String])
    func saveEndpoint(_ url: String)
    func saveMode(_ mode: String)
    func savePermissions(_ state: PermissionState)
    func markLaunched()
    func loadConfig() -> LoadedConfig
}

struct LoadedConfig {
    var mode: String?
    var firstLaunch: Bool
    var tracking: [String: String]
    var navigation: [String: String]
    var permissions: LoadedPermissions
    
    struct LoadedPermissions {
        var approved: Bool
        var declined: Bool
        var lastAsked: Date?
    }
}

protocol ValidationPort {
    func validate() async throws -> Bool
}

protocol NetworkPort {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func fetchEndpoint(tracking: [String: Any]) async throws -> String
}

protocol NotificationPort {
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    func registerForRemoteNotifications()
}

protocol EventPublisher {
    func publish(_ event: DomainEvent)
}
