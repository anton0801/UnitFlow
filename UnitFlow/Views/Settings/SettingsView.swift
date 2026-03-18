import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: ApplicationMainState
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @EnvironmentObject var sitesVM: SitesViewModel

    @State private var showEditProfile = false
    @State private var showExportSheet = false
    @State private var showLogoutAlert = false
    @State private var showClearDataAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showConfirmation = false
    @State private var confirmationMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // MARK: Profile Card
                        Button { showEditProfile = true } label: {
                            UFCard {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(UFColors.gradientOrange)
                                            .frame(width: 58, height: 58)
                                            .shadow(color: UFColors.primary.opacity(0.35), radius: 8, x: 0, y: 4)
                                        Text(initials)
                                            .font(UFFont.display(20))
                                            .foregroundColor(.white)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(authVM.currentUser?.fullName ?? "User")
                                            .font(UFFont.headline(16))
                                            .foregroundColor(.primary)
                                        Text(authVM.currentUser?.companyName ?? "")
                                            .font(UFFont.caption(13))
                                            .foregroundColor(.secondary)
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 9))
                                                .foregroundColor(UFColors.primary)
                                            Text(authVM.currentUser?.role.rawValue ?? "")
                                                .font(UFFont.caption(12))
                                                .foregroundColor(UFColors.primary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(ScaleButtonStyle())

                        // MARK: Appearance
                        SettingsSection(title: "Appearance") {
                            SettingsRow(icon: "circle.lefthalf.filled", iconColor: UFColors.primary, title: "Theme") {
                                Picker("Theme", selection: Binding(
                                    get: { appState.appTheme },
                                    set: { newVal in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            appState.appTheme = newVal
                                        }
                                    }
                                )) {
                                    Text("System").tag("system")
                                    Text("Light").tag("light")
                                    Text("Dark").tag("dark")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 168)
                            }

                            SettingsDivider()

                            SettingsRow(icon: "ruler.fill", iconColor: UFColors.info, title: "Measurement Units") {
                                Picker("Units", selection: Binding(
                                    get: { appState.measurementUnit },
                                    set: { appState.measurementUnit = $0 }
                                )) {
                                    Text("Metric").tag("metric")
                                    Text("Imperial").tag("imperial")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                            }
                        }

                        // MARK: Notifications
                        SettingsSection(title: "Notifications") {
                            SettingsRow(icon: "bell.badge.fill", iconColor: UFColors.warning, title: "Enable Notifications") {
                                Toggle("", isOn: Binding(
                                    get: { appState.notificationsEnabled },
                                    set: { enabled in
                                        if enabled {
                                            notificationsVM.requestPermission { granted in
                                                appState.notificationsEnabled = granted
                                                if !granted {
                                                    showToast("Notifications blocked in Settings")
                                                }
                                            }
                                        } else {
                                            appState.notificationsEnabled = false
                                            notificationsVM.cancelAllNotifications()
                                            showToast("Notifications disabled")
                                        }
                                    }
                                ))
                                .labelsHidden()
                                .tint(UFColors.primary)
                            }

                            if appState.notificationsEnabled {
                                SettingsDivider()
                                SettingsRow(icon: "clock.badge.exclamationmark.fill", iconColor: UFColors.danger, title: "Overdue Tasks") {
                                    Toggle("", isOn: Binding(
                                        get: { appState.overdueTaskAlerts },
                                        set: { appState.overdueTaskAlerts = $0 }
                                    ))
                                    .labelsHidden().tint(UFColors.primary)
                                }

                                SettingsDivider()
                                SettingsRow(icon: "exclamationmark.octagon.fill", iconColor: UFColors.danger, title: "Critical Issues") {
                                    Toggle("", isOn: Binding(
                                        get: { appState.criticalIssueAlerts },
                                        set: { appState.criticalIssueAlerts = $0 }
                                    ))
                                    .labelsHidden().tint(UFColors.primary)
                                }

                                SettingsDivider()
                                SettingsRow(icon: "doc.text.fill", iconColor: UFColors.success, title: "Daily Report Reminder") {
                                    Toggle("", isOn: Binding(
                                        get: { appState.reportReminderAlerts },
                                        set: { enabled in
                                            appState.reportReminderAlerts = enabled
                                            if enabled {
                                                notificationsVM.scheduleReportReminder()
                                                showToast("Reminder set for 5:00 PM daily")
                                            } else {
                                                notificationsVM.cancelReportReminder()
                                                showToast("Report reminder cancelled")
                                            }
                                        }
                                    ))
                                    .labelsHidden().tint(UFColors.primary)
                                }

                                SettingsDivider()
                                SettingsRow(icon: "shippingbox.fill", iconColor: UFColors.info, title: "Material Delays") {
                                    Toggle("", isOn: Binding(
                                        get: { appState.materialDelayAlerts },
                                        set: { appState.materialDelayAlerts = $0 }
                                    ))
                                    .labelsHidden().tint(UFColors.primary)
                                }

                                SettingsDivider()
                                SettingsRow(icon: "person.fill.xmark", iconColor: UFColors.warning, title: "Worker Missing") {
                                    Toggle("", isOn: Binding(
                                        get: { appState.workerMissingAlerts },
                                        set: { appState.workerMissingAlerts = $0 }
                                    ))
                                    .labelsHidden().tint(UFColors.primary)
                                }
                            }
                        }

                        // MARK: Data Management
                        SettingsSection(title: "Data") {
                            SettingsNavRow(
                                icon: "square.and.arrow.up.fill",
                                iconColor: UFColors.success,
                                title: "Export All Data",
                                subtitle: "Save as JSON file"
                            ) {
                                showExportSheet = true
                            }

                            SettingsDivider()

                            NavigationLink {
                                AnalyticsView()
                            } label: {
                                SettingsRowContent(
                                    icon: "chart.bar.fill",
                                    iconColor: UFColors.primary,
                                    title: "Analytics & Reports"
                                ) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            }

                            SettingsDivider()

                            SettingsNavRow(
                                icon: "trash.fill",
                                iconColor: UFColors.danger,
                                title: "Clear All Data",
                                subtitle: "Cannot be undone"
                            ) {
                                showClearDataAlert = true
                            }
                        }

                        // MARK: About
                        SettingsSection(title: "About") {
                            SettingsInfoRow(icon: "info.circle.fill", iconColor: UFColors.info, title: "Version", value: "1.0.0")
                            SettingsDivider()
                            SettingsInfoRow(icon: "building.2.fill", iconColor: UFColors.primary, title: "Active Sites", value: "\(sitesVM.activeSitesCount)")
                            SettingsDivider()
                            SettingsInfoRow(icon: "exclamationmark.triangle.fill", iconColor: UFColors.danger, title: "Open Issues", value: "\(sitesVM.openIssuesCount)")
                            SettingsDivider()
                            SettingsInfoRow(icon: "doc.text.fill", iconColor: .secondary, title: "Reports Filed", value: "\(sitesVM.reports.count)")
                        }

                        // MARK: Sign Out
                        Button {
                            showLogoutAlert = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Sign Out")
                                    .font(UFFont.headline(16))
                            }
                            .foregroundColor(UFColors.danger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(UFColors.danger.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(UFColors.danger.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)

                        // MARK: Delete Account
                        Button {
                            showDeleteAccountAlert = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "person.crop.circle.badge.minus")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Delete Account")
                                    .font(UFFont.headline(16))
                            }
                            .foregroundColor(UFColors.danger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(UFColors.danger.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(UFColors.danger.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .padding(.top, 8)
                }

                // MARK: Confirmation Toast
                if showConfirmation {
                    VStack {
                        Spacer()
                        ConfirmationToast(message: confirmationMessage)
                            .padding(.bottom, 100)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        // MARK: Sheets & Alerts
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showExportSheet) {
            DataExportView()
        }
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authVM.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Clear All Data", isPresented: $showClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Everything", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all sites, reports, issues, and worker data. This cannot be undone.")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Account", role: .destructive) {
                authVM.deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This cannot be undone.")
        }
    }

    // MARK: Helpers
    private var initials: String {
        let name = authVM.currentUser?.fullName ?? "U"
        return name.components(separatedBy: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
    }

    private func showToast(_ message: String) {
        confirmationMessage = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showConfirmation = false }
        }
    }

    private func clearAllData() {
        let keys = [
            "unitflow_sites", "unitflow_reports", "unitflow_issues",
            "unitflow_tasks", "unitflow_photos", "unitflow_materials",
            "unitflow_deliveries", "unitflow_documents", "unitflow_timeline",
            "unitflow_workers", "unitflow_attendance"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        sitesVM.sites = []
        sitesVM.reports = []
        sitesVM.issues = []
        sitesVM.tasks = []
        sitesVM.photos = []
        sitesVM.materials = []
        sitesVM.deliveries = []
        sitesVM.documents = []
        sitesVM.timeline = []
        showToast("All data cleared")
    }
}

// MARK: - Settings Section Container
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.colorScheme) var colorScheme

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(UFFont.caption(11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content
            }
            .background(colorScheme == .dark ? Color(hex: "#2A2A3E") : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: Content

    init(icon: String, iconColor: Color, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.content = content()
    }

    var body: some View {
        SettingsRowContent(icon: icon, iconColor: iconColor, title: title, content: { content })
    }
}

struct SettingsRowContent<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: Content

    init(icon: String, iconColor: Color, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(UFFont.body(15))
                .foregroundColor(.primary)
            Spacer()
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider().padding(.leading, 60)
    }
}

struct SettingsNavRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(UFFont.body(15))
                        .foregroundColor(.primary)
                    if let sub = subtitle {
                        Text(sub)
                            .font(UFFont.caption(12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(UFFont.body(15))
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(UFFont.caption(14))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authVM: AuthViewModel

    @State private var fullName: String = ""
    @State private var companyName: String = ""
    @State private var role: User.UserRole = .foreman
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(UFColors.gradientOrange)
                                .frame(width: 90, height: 90)
                                .shadow(color: UFColors.primary.opacity(0.4), radius: 14, x: 0, y: 6)
                            Text(fullName.components(separatedBy: " ").compactMap { $0.first.map(String.init) }.prefix(2).joined())
                                .font(UFFont.display(30))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        FormSection(title: "Personal Information") {
                            UFTextField(icon: "person.fill", placeholder: "Full Name", text: $fullName)
                            UFTextField(icon: "building.2.fill", placeholder: "Company Name", text: $companyName)
                        }

                        FormSection(title: "Role") {
                            VStack(spacing: 8) {
                                ForEach(User.UserRole.allCases, id: \.self) { r in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            role = r
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: role == r ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 18))
                                                .foregroundColor(role == r ? UFColors.primary : .secondary)
                                            Text(r.rawValue)
                                                .font(UFFont.body(15))
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(role == r ? UFColors.primary.opacity(0.08) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        Button {
                            guard !fullName.isEmpty else { return }
                            authVM.updateProfile(fullName: fullName, companyName: companyName, role: role)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        } label: {
                            HStack {
                                if showConfirmation {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Profile Saved!")
                                } else {
                                    Text("Save Profile")
                                }
                            }
                            .font(UFFont.headline(17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(fullName.isEmpty ? LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) : UFColors.gradientOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: UFColors.primary.opacity(0.3), radius: 10, x: 0, y: 4)
                        }
                        .disabled(fullName.isEmpty)
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(UFColors.primary)
                }
            }
            .onAppear {
                fullName = authVM.currentUser?.fullName ?? ""
                companyName = authVM.currentUser?.companyName ?? ""
                role = authVM.currentUser?.role ?? .foreman
            }
        }
    }
}

// MARK: - Data Export View
struct DataExportView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    @EnvironmentObject var workersVM: WorkersViewModel

    @State private var exportedJSON: String = ""
    @State private var isGenerating = true
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                VStack(spacing: 20) {
                    if isGenerating {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(UFColors.primary)
                            Text("Generating export...")
                                .font(UFFont.body(15))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        VStack(spacing: 16) {
                            // Summary
                            UFCard {
                                VStack(spacing: 12) {
                                    ExportStatRow(icon: "building.2.fill", label: "Sites", value: "\(sitesVM.sites.count)", color: UFColors.primary)
                                    Divider()
                                    ExportStatRow(icon: "doc.text.fill", label: "Reports", value: "\(sitesVM.reports.count)", color: UFColors.success)
                                    Divider()
                                    ExportStatRow(icon: "exclamationmark.triangle.fill", label: "Issues", value: "\(sitesVM.issues.count)", color: UFColors.danger)
                                    Divider()
                                    ExportStatRow(icon: "person.3.fill", label: "Workers", value: "\(workersVM.workers.count)", color: UFColors.info)
                                    Divider()
                                    ExportStatRow(icon: "cube.fill", label: "Material Requests", value: "\(sitesVM.materials.count)", color: UFColors.warning)
                                }
                            }
                            .padding(.horizontal, 20)

                            Text("Format: JSON  •  \(formattedDate)")
                                .font(UFFont.caption(13))
                                .foregroundColor(.secondary)

                            // JSON preview
                            ScrollView {
                                Text(exportedJSON.prefix(1200) + (exportedJSON.count > 1200 ? "\n... (\(exportedJSON.count) characters total)" : ""))
                                    .font(UFFont.mono(11))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                            }
                            .frame(height: 180)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)

                            Button {
                                showShareSheet = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Share Export File")
                                        .font(UFFont.headline(16))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(UFColors.gradientOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: UFColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(UFColors.primary)
                }
            }
            .onAppear { generateExport() }
            .sheet(isPresented: $showShareSheet) {
                if let data = exportedJSON.data(using: .utf8) {
                    ShareSheet(items: [data as Any])
                }
            }
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy HH:mm"
        return f.string(from: Date())
    }

    private func generateExport() {
        DispatchQueue.global(qos: .userInitiated).async {
            let export = ExportData(
                exportDate: Date(),
                sitesCount: sitesVM.sites.count,
                reportsCount: sitesVM.reports.count,
                issuesCount: sitesVM.issues.count,
                workersCount: workersVM.workers.count,
                sites: sitesVM.sites.map { ExportSite(id: $0.id.uuidString, name: $0.name, address: $0.address, status: $0.status.rawValue, progress: $0.progressPercent) },
                issues: sitesVM.issues.map { ExportIssue(id: $0.id.uuidString, title: $0.title, severity: $0.severity.rawValue, status: $0.status.rawValue) }
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            if let data = try? encoder.encode(export),
               let json = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    exportedJSON = json
                    withAnimation { isGenerating = false }
                }
            }
        }
    }
}

struct ExportData: Codable {
    let exportDate: Date
    let sitesCount: Int
    let reportsCount: Int
    let issuesCount: Int
    let workersCount: Int
    let sites: [ExportSite]
    let issues: [ExportIssue]
}

struct ExportSite: Codable {
    let id: String
    let name: String
    let address: String
    let status: String
    let progress: Double
}

struct ExportIssue: Codable {
    let id: String
    let title: String
    let severity: String
    let status: String
}

struct ExportStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            Text(label).font(UFFont.body(14)).foregroundColor(.primary)
            Spacer()
            Text(value).font(UFFont.headline(14)).foregroundColor(color)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @EnvironmentObject var sitesVM: SitesViewModel
    @EnvironmentObject var workersVM: WorkersViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Overall Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        AnalyticsCard(value: "\(sitesVM.activeSitesCount)", label: "Active Sites", icon: "building.2.fill", color: UFColors.primary)
                        AnalyticsCard(value: "\(sitesVM.openIssuesCount)", label: "Open Issues", icon: "exclamationmark.triangle.fill", color: UFColors.danger)
                        AnalyticsCard(value: "\(sitesVM.tasks.filter{$0.status == .done}.count)", label: "Tasks Done", icon: "checkmark.circle.fill", color: UFColors.success)
                        AnalyticsCard(value: "\(workersVM.onSiteCount())", label: "Workers Active", icon: "person.fill.checkmark", color: UFColors.info)
                    }
                    .padding(.horizontal, 20)

                    // Progress by Site
                    if !sitesVM.sites.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            UFSectionHeader(title: "Site Progress").padding(.horizontal, 20)

                            ForEach(sitesVM.sites) { site in
                                UFCard(padding: 14) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(site.name)
                                                .font(UFFont.headline(14))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(Int(site.progressPercent))%")
                                                .font(UFFont.headline(13))
                                                .foregroundColor(UFColors.primary)
                                        }
                                        UFProgressBar(progress: site.progressPercent, height: 10)

                                        HStack {
                                            let done = site.stages.filter { $0.status == .done }.count
                                            Text("\(done)/\(site.stages.count) stages complete")
                                                .font(UFFont.caption(11))
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            let open = sitesVM.openIssues(for: site.id)
                                            if open > 0 {
                                                Text("\(open) open issues")
                                                    .font(UFFont.caption(11))
                                                    .foregroundColor(UFColors.danger)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Issues by Severity
                    if !sitesVM.issues.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            UFSectionHeader(title: "Issues by Severity").padding(.horizontal, 20)

                            UFCard {
                                VStack(spacing: 14) {
                                    ForEach(Issue.Severity.allCases, id: \.self) { sev in
                                        let count = sitesVM.issues.filter { $0.severity == sev }.count
                                        let total = max(sitesVM.issues.count, 1)
                                        HStack(spacing: 10) {
                                            Text(sev.rawValue)
                                                .font(UFFont.caption(13))
                                                .foregroundColor(.primary)
                                                .frame(width: 60, alignment: .leading)
                                            UFProgressBar(progress: Double(count) / Double(total) * 100, height: 8, color: sev.color)
                                            Text("\(count)")
                                                .font(UFFont.headline(13))
                                                .foregroundColor(sev.color)
                                                .frame(width: 24, alignment: .trailing)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Worker Attendance Summary
                    if !workersVM.workers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            UFSectionHeader(title: "Team Status").padding(.horizontal, 20)

                            UFCard {
                                VStack(spacing: 12) {
                                    ForEach(Worker.WorkerStatus.allCases, id: \.self) { st in
                                        let count = workersVM.workers.filter { $0.status == st }.count
                                        HStack {
                                            Image(systemName: st.icon)
                                                .font(.system(size: 14))
                                                .foregroundColor(st.color)
                                                .frame(width: 20)
                                            Text(st.rawValue)
                                                .font(UFFont.body(14))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text("\(count)")
                                                .font(UFFont.headline(14))
                                                .foregroundColor(st.color)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Material Requests by Status
                    if !sitesVM.materials.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            UFSectionHeader(title: "Material Requests").padding(.horizontal, 20)

                            UFCard {
                                VStack(spacing: 12) {
                                    ForEach(MaterialRequest.RequestStatus.allCases, id: \.self) { st in
                                        let count = sitesVM.materials.filter { $0.status == st }.count
                                        HStack {
                                            StatusBadge(text: st.rawValue, color: st.color, small: true)
                                            Spacer()
                                            Text("\(count)")
                                                .font(UFFont.headline(13))
                                                .foregroundColor(st.color)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct AnalyticsCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        UFCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(value)
                    .font(UFFont.display(26))
                    .foregroundColor(.primary)
                Text(label)
                    .font(UFFont.caption(12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
