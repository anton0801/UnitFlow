import SwiftUI

// MARK: - Report Config Sheet
struct ReportConfigSheet: View {
    let site: ConstructionSite
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @StateObject private var generator = PDFReportGenerator()
    @State private var config: ReportConfig = {
        let now = Date()
        let weekStart = Calendar.current.startOfDay(for: now)
        return ReportConfig(periodStart: weekStart, periodEnd: now)
    }()
    @State private var branding = ReportBranding.load()
    @State private var selectedPeriod: PeriodOption = .thisWeek
    @State private var showCustomPicker = false
    @State private var showShareSheet = false
    @State private var generatedURL: URL? = nil

    enum PeriodOption: String, CaseIterable {
        case thisWeek  = "This Week"
        case lastWeek  = "Last Week"
        case thisMonth = "This Month"
        case custom    = "Custom"
    }

    var sitePhotos: [SitePhoto] { sitesVM.photos(for: site.id) }
    var siteIssues: [Issue]     { sitesVM.issues(for: site.id) }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                if generator.isGenerating {
                    generatingOverlay
                } else if let url = generatedURL {
                    generatedView(url: url)
                } else {
                    configForm
                }
            }
            .navigationTitle("Generate Client Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
        .onReceive(generator.$generatedURL.compactMap { $0 }) { url in
            generatedURL = url
        }
    }

    // MARK: Config form
    var configForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // Period
                FormSection(title: "Report Period") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(PeriodOption.allCases.filter { $0 != .custom }, id: \.self) { option in
                                Button {
                                    selectedPeriod = option
                                    applyPeriod(option)
                                } label: {
                                    Text(option.rawValue)
                                        .font(UFFont.caption(12))
                                        .foregroundColor(selectedPeriod == option ? .white : .secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(selectedPeriod == option ? UFColors.primary : Color.gray.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }

                        Button {
                            selectedPeriod = .custom
                            showCustomPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(UFColors.primary)
                                Text(selectedPeriod == .custom
                                     ? "\(DateFormatter.ufDate.string(from: config.periodStart)) – \(DateFormatter.ufDate.string(from: config.periodEnd))"
                                     : "Custom Range...")
                                    .font(UFFont.caption(13))
                                    .foregroundColor(selectedPeriod == .custom ? .primary : .secondary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }

                // Include sections
                FormSection(title: "Include Sections") {
                    VStack(spacing: 0) {
                        toggleRow("Cover Page",           icon: "doc.richtext", binding: $config.includeCover)
                        toggleRow("Progress Overview",    icon: "chart.pie",    binding: $config.includeProgress)
                        toggleRow("Stage Completion",     icon: "list.bullet.rectangle", binding: $config.includeStages)
                        toggleRow("Photo Gallery",        icon: "photo.on.rectangle",    binding: $config.includePhotos)
                        toggleRow("Active Issues",        icon: "exclamationmark.triangle", binding: $config.includeIssues)
                        toggleRow("Worker Attendance",    icon: "person.3",     binding: $config.includeAttendance)
                        toggleRow("Material Deliveries",  icon: "shippingbox",  binding: $config.includeMaterials)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Photos per page
                FormSection(title: "Photos Per Page") {
                    HStack(spacing: 12) {
                        ForEach([2, 4, 6], id: \.self) { n in
                            Button {
                                config.photosPerPage = n
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: photoIcon(n))
                                        .font(.system(size: 18))
                                        .foregroundColor(config.photosPerPage == n ? .white : UFColors.primary)
                                    Text("\(n)")
                                        .font(UFFont.headline(14))
                                        .foregroundColor(config.photosPerPage == n ? .white : .primary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                                .background(config.photosPerPage == n ? UFColors.primary : UFColors.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }

                // Generate button
                Button {
                    generateReport()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.badge.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Generate Report →")
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
                .padding(.horizontal, 4)

                // Branding settings link
                NavigationLink {
                    ReportBrandingSettings()
                } label: {
                    HStack {
                        Image(systemName: "paintpalette")
                            .foregroundColor(UFColors.primary)
                        Text("Report Branding Settings")
                            .font(UFFont.caption(14))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Color.clear.frame(height: 40)
            }
            .padding(20)
        }
        .sheet(isPresented: $showCustomPicker) {
            DateRangePickerSheet(startDate: $config.periodStart, endDate: $config.periodEnd)
        }
    }

    // MARK: Generating overlay
    var generatingOverlay: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(UFColors.primary)

            Text("Building your report...")
                .font(UFFont.headline(16))

            VStack(spacing: 8) {
                HStack {
                    Text(generationStepLabel)
                        .font(UFFont.caption(13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(generator.progress))%")
                        .font(UFFont.mono(13))
                        .foregroundColor(UFColors.primary)
                }
                UFProgressBar(progress: generator.progress, height: 8, color: UFColors.primary)
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
    }

    var generationStepLabel: String {
        switch generator.progress {
        case 0..<15:  return "Fetching data..."
        case 15..<45: return "Rendering pages..."
        case 45..<80: return "Processing photos..."
        case 80..<95: return "Compressing..."
        default:      return "Finalising PDF..."
        }
    }

    // MARK: Generated view
    func generatedView(url: URL) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(UFColors.success)

            Text("Report Ready!")
                .font(UFFont.headline(22))

            Text("Your PDF has been saved to the app documents folder.")
                .font(UFFont.body(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share PDF")
                        .font(UFFont.headline(16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(UFColors.gradientOrange)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: UFColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)

            Button {
                generatedURL = nil
            } label: {
                Text("Generate Another")
                    .font(UFFont.caption(14))
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [url])
        }
    }

    // MARK: Helpers
    func toggleRow(_ label: String, icon: String, binding: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(UFColors.primary)
                .frame(width: 24)
            Text(label)
                .font(UFFont.body(14))
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(UFColors.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    func photoIcon(_ n: Int) -> String {
        switch n {
        case 2: return "rectangle.split.1x2"
        case 4: return "rectangle.split.2x2"
        default: return "rectangle.grid.2x2"
        }
    }

    func applyPeriod(_ option: PeriodOption) {
        let cal = Calendar.current
        let now = Date()
        switch option {
        case .thisWeek:
            config.periodStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            config.periodEnd   = now
        case .lastWeek:
            let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            config.periodStart = cal.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? now
            config.periodEnd   = cal.date(byAdding: .day, value: -1, to: thisWeekStart) ?? now
        case .thisMonth:
            config.periodStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
            config.periodEnd   = now
        case .custom:
            break
        }
    }

    func generateReport() {
        branding = ReportBranding.load()
        let userName = authVM.currentUser.map { "\($0.fullName), \($0.role.rawValue)" } ?? "Site Manager"
        Task {
            await generator.generate(
                site: site,
                photos: sitePhotos,
                issues: siteIssues,
                config: config,
                branding: branding,
                userName: userName
            )
        }
    }
}

// MARK: - Date range picker sheet
struct DateRangePickerSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                VStack(spacing: 20) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .font(UFFont.headline(15))
                }
            }
        }
    }
}

// Note: ShareSheet is defined in SettingsView.swift and available project-wide.
