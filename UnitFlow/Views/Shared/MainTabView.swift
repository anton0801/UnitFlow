import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var sitesVM: SitesViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                SitesListView()
                    .tag(1)
                IssuesListView()
                    .tag(2)
                WorkersListView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var sitesVM: SitesViewModel
    
    let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Dashboard"),
        ("building.2.fill", "Sites"),
        ("exclamationmark.triangle.fill", "Issues"),
        ("person.3.fill", "Team"),
        ("gearshape.fill", "Settings")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { idx in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = idx
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == idx {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(UFColors.primary.opacity(0.15))
                                    .frame(width: 48, height: 32)
                            }
                            
                            Image(systemName: tabs[idx].icon)
                                .font(.system(size: selectedTab == idx ? 20 : 18, weight: .semibold))
                                .foregroundColor(selectedTab == idx ? UFColors.primary : .secondary)
                                .scaleEffect(selectedTab == idx ? 1.1 : 1.0)
                            
                            // Badge for issues
                            if idx == 2 && sitesVM.criticalIssuesCount > 0 {
                                Circle()
                                    .fill(UFColors.danger)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 10, y: -8)
                            }
                        }
                        .frame(width: 48, height: 32)
                        
                        Text(tabs[idx].label)
                            .font(UFFont.caption(10))
                            .foregroundColor(selectedTab == idx ? UFColors.primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, max(UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0, 16))
        .background(
            (colorScheme == .dark ? Color(hex: "#1E1E2E") : Color.white)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
        )
    }
}
