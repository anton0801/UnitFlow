import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var sitesVM: SitesViewModel
    @EnvironmentObject var workersVM: WorkersViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showNewReport = false
    @State private var showNewIssue = false
    @State private var showNewSite = false
    @State private var selectedSite: ConstructionSite? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(greeting())
                                    .font(UFFont.body(14))
                                    .foregroundColor(.secondary)
                                Text(authVM.currentUser?.fullName ?? "Builder")
                                    .font(UFFont.display(24))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(UFColors.gradientOrange)
                                    .frame(width: 44, height: 44)
                                Text(initials)
                                    .font(UFFont.headline(16))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Stats Row
                        HStack(spacing: 12) {
                            StatCard(value: "\(sitesVM.activeSitesCount)", label: "Active Sites", icon: "building.2.fill", color: UFColors.primary)
                            StatCard(value: "\(sitesVM.openIssuesCount)", label: "Open Issues", icon: "exclamationmark.triangle.fill", color: sitesVM.openIssuesCount > 0 ? UFColors.danger : UFColors.success)
                            StatCard(value: "\(workersVM.onSiteCount())", label: "On Site", icon: "person.fill.checkmark", color: UFColors.success)
                        }
                        .padding(.horizontal, 20)
                        
                        // Today Summary
                        VStack(spacing: 12) {
                            UFSectionHeader(title: "Today's Summary")
                                .padding(.horizontal, 20)
                            
                            UFCard {
                                VStack(spacing: 14) {
                                    SummaryRow(icon: "checkmark.circle.fill", color: UFColors.success,
                                               title: "Tasks Due Today", value: "\(sitesVM.todayTasks().count)")
                                    Divider()
                                    SummaryRow(icon: "exclamationmark.triangle.fill", color: UFColors.danger,
                                               title: "Open Issues", value: "\(sitesVM.openIssuesCount)")
                                    Divider()
                                    SummaryRow(icon: "person.3.fill", color: UFColors.info,
                                               title: "Workers On Site", value: "\(workersVM.onSiteCount())")
                                    Divider()
                                    SummaryRow(icon: "shippingbox.fill", color: UFColors.primary,
                                               title: "Pending Materials", value: "\(sitesVM.materials.filter { $0.status == .requested }.count)")
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Quick Actions
                        VStack(spacing: 12) {
                            UFSectionHeader(title: "Quick Actions")
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                QuickActionCard(icon: "doc.text.fill", title: "Daily Report", subtitle: "Log today's work", color: UFColors.primary) {
                                    showNewReport = true
                                }
                                QuickActionCard(icon: "exclamationmark.triangle.fill", title: "Log Issue", subtitle: "Report a problem", color: UFColors.danger) {
                                    showNewIssue = true
                                }
                                QuickActionCard(icon: "plus.circle.fill", title: "New Site", subtitle: "Add a project", color: UFColors.success) {
                                    showNewSite = true
                                }
                                NavigationLink {
                                    PhotosView(siteId: nil)
                                } label: {
                                    QuickActionCardContent(icon: "camera.fill", title: "Add Photo", subtitle: "Document progress", color: UFColors.info)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Active Sites
                        if !sitesVM.sites.filter({ $0.status == .active }).isEmpty {
                            VStack(spacing: 12) {
                                UFSectionHeader(title: "Active Sites") {
                                    // handled by tab navigation
                                }
                                .padding(.horizontal, 20)
                                
                                ForEach(sitesVM.sites.filter { $0.status == .active }) { site in
                                    NavigationLink {
                                        SiteDetailView(site: site)
                                    } label: {
                                        DashboardSiteCard(site: site, issueCount: sitesVM.openIssues(for: site.id))
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Risk Alerts
                        if sitesVM.criticalIssuesCount > 0 {
                            VStack(spacing: 12) {
                                UFSectionHeader(title: "⚠️ Risk Alerts")
                                    .padding(.horizontal, 20)
                                
                                ForEach(sitesVM.issues.filter { $0.severity == .critical && $0.status != .resolved }.prefix(3)) { issue in
                                    AlertCard(issue: issue)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showNewReport) {
            NewReportView()
        }
        .sheet(isPresented: $showNewIssue) {
            NewIssueView(preselectedSiteId: sitesVM.sites.first?.id)
        }
        .sheet(isPresented: $showNewSite) {
            NewSiteView()
        }
    }
    
    var initials: String {
        let name = authVM.currentUser?.fullName ?? "U"
        return name.components(separatedBy: " ").compactMap { $0.first.map(String.init) }.joined()
    }
    
    func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning," }
        else if hour < 17 { return "Good afternoon," }
        else { return "Good evening," }
    }
}

// MARK: - Sub-components
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        UFCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                Text(value)
                    .font(UFFont.display(22))
                    .foregroundColor(.primary)
                Text(label)
                    .font(UFFont.caption(11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .font(UFFont.body(14))
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(UFFont.headline(14))
                .foregroundColor(color)
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            QuickActionCardContent(icon: icon, title: title, subtitle: subtitle, color: color)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct QuickActionCardContent: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(UFFont.headline(13))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(UFFont.caption(11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(colorScheme == .dark ? Color(hex: "#2A2A3E") : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.07), radius: 6, x: 0, y: 3)
    }
}

struct DashboardSiteCard: View {
    let site: ConstructionSite
    let issueCount: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        UFCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: site.siteType.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(UFColors.primary)
                    Text(site.name)
                        .font(UFFont.headline(15))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    StatusBadge(text: site.status.rawValue, color: site.status.color, small: true)
                }
                
                Text(site.address)
                    .font(UFFont.caption(12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                VStack(spacing: 6) {
                    HStack {
                        Text("Progress")
                            .font(UFFont.caption(12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(site.progressPercent))%")
                            .font(UFFont.headline(12))
                            .foregroundColor(UFColors.primary)
                    }
                    UFProgressBar(progress: site.progressPercent)
                }
                
                HStack {
                    if issueCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(UFColors.danger)
                            Text("\(issueCount) issues")
                                .font(UFFont.caption(11))
                                .foregroundColor(UFColors.danger)
                        }
                    }
                    Spacer()
                    Text("Due: \(DateFormatter.ufShort.string(from: site.plannedEndDate))")
                        .font(UFFont.caption(11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct AlertCard: View {
    let issue: Issue
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(UFColors.danger)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.title)
                    .font(UFFont.headline(14))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(issue.zone + " • " + issue.severity.rawValue)
                    .font(UFFont.caption(12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            StatusBadge(text: issue.status.rawValue, color: issue.status.color, small: true)
        }
        .padding(14)
        .background(UFColors.danger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(UFColors.danger.opacity(0.2), lineWidth: 1)
        )
    }
}
