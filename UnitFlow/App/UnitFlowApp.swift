import SwiftUI

@main
struct UnitFlowApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var sitesVM = SitesViewModel()
    @StateObject private var workersVM = WorkersViewModel()
    @StateObject private var notificationsVM = NotificationsViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authVM)
                .environmentObject(sitesVM)
                .environmentObject(workersVM)
                .environmentObject(notificationsVM)
                .preferredColorScheme(appState.colorScheme)
                .accentColor(UFColors.primary)
        }
    }
}
