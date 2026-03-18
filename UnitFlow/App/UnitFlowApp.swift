import SwiftUI

@main
struct UnitFlowApp: App {
    @StateObject private var appState = ApplicationMainState()
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var sitesVM = SitesViewModel()
    @StateObject private var workersVM = WorkersViewModel()
    @StateObject private var notificationsVM = NotificationsViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            SplashView()
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
