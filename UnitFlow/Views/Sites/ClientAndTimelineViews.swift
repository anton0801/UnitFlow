import SwiftUI

// MARK: - Client Summary View
struct ClientSummaryView: View {
    let site: ConstructionSite
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showShareSheet = false
    @State private var summaryText = ""
    @State private var showPDFReport = false

    var completedStages: [WorkStage] {
        site.stages.filter { $0.status == .done }
    }

    var activeIssues: [Issue] {
        sitesVM.issues(for: site.id).filter { $0.status != .resolved }
    }

    var recentPhotos: [SitePhoto] {
        Array(sitesVM.photos(for: site.id).prefix(6))
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Header Banner
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(UFColors.gradientDark)
                            .frame(height: 160)

                        VStack(spacing: 10) {
                            Text(site.name)
                                .font(UFFont.display(24))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("Client Progress Summary")
                                .font(UFFont.caption(14))
                                .foregroundColor(.white.opacity(0.6))

                            HStack(spacing: 16) {
                                VStack(spacing: 2) {
                                    Text("\(Int(site.progressPercent))%")
                                        .font(UFFont.headline(22))
                                        .foregroundColor(UFColors.primary)
                                    Text("Complete").font(UFFont.caption(11)).foregroundColor(.white.opacity(0.6))
                                }
                                Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 32)
                                VStack(spacing: 2) {
                                    Text("\(completedStages.count)")
                                        .font(UFFont.headline(22))
                                        .foregroundColor(UFColors.success)
                                    Text("Stages Done").font(UFFont.caption(11)).foregroundColor(.white.opacity(0.6))
                                }
                                Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 32)
                                VStack(spacing: 2) {
                                    Text("\(activeIssues.count)")
                                        .font(UFFont.headline(22))
                                        .foregroundColor(activeIssues.isEmpty ? UFColors.success : UFColors.warning)
                                    Text("Open Issues").font(UFFont.caption(11)).foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 20)

                    // Progress Bar
                    UFCard {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Overall Progress")
                                    .font(UFFont.headline(14))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Due \(DateFormatter.ufDate.string(from: site.plannedEndDate))")
                                    .font(UFFont.caption(12))
                                    .foregroundColor(.secondary)
                            }
                            UFProgressBar(progress: site.progressPercent, height: 12)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Completed Stages
                    if !completedStages.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            UFSectionHeader(title: "✅ Completed Stages").padding(.horizontal, 20)
                            UFCard {
                                VStack(spacing: 8) {
                                    ForEach(completedStages) { stage in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(UFColors.success)
                                            Text(stage.name)
                                                .font(UFFont.body(14))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            StatusBadge(text: "Done", color: UFColors.success, small: true)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Recent Photos
                    if !recentPhotos.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            UFSectionHeader(title: "Recent Photos").padding(.horizontal, 20)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(recentPhotos) { photo in
                                        if let uiImage = UIImage(data: photo.imageData) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Image(uiImage: uiImage)
                                                    .resizable().scaledToFill()
                                                    .frame(width: 130, height: 100)
                                                    .clipped()
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                Text(photo.type.rawValue)
                                                    .font(UFFont.caption(10))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Active Issues
                    if !activeIssues.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            UFSectionHeader(title: "⚠️ Active Issues").padding(.horizontal, 20)
                            ForEach(activeIssues.prefix(3)) { issue in
                                UFCard(padding: 12) {
                                    HStack {
                                        Image(systemName: issue.category.icon)
                                            .foregroundColor(issue.severity.color)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(issue.title).font(UFFont.headline(13)).foregroundColor(.primary)
                                            Text(issue.zone).font(UFFont.caption(11)).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        StatusBadge(text: issue.severity.rawValue, color: issue.severity.color, small: true)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Export PDF button
                    Button {
                        showPDFReport = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.richtext.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Export PDF Report")
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

                    // Share text summary button
                    Button {
                        summaryText = generateSummaryText()
                        showShareSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Share Text Summary")
                                .font(UFFont.headline(16))
                        }
                        .foregroundColor(UFColors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(UFColors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Client Summary")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [summaryText])
        }
        .sheet(isPresented: $showPDFReport) {
            ReportConfigSheet(site: site)
        }
    }

    private func generateSummaryText() -> String {
        var text = "📋 PROJECT UPDATE: \(site.name)\n"
        text += "📍 \(site.address)\n"
        text += "📅 Report Date: \(DateFormatter.ufDate.string(from: Date()))\n\n"
        text += "✅ PROGRESS: \(Int(site.progressPercent))% complete\n"
        text += "🏗️ Completed Stages: \(completedStages.map { $0.name }.joined(separator: ", "))\n"
        if activeIssues.isEmpty {
            text += "🟢 No active issues\n"
        } else {
            text += "⚠️ Active Issues: \(activeIssues.count)\n"
        }
        text += "\nPlanned completion: \(DateFormatter.ufDate.string(from: site.plannedEndDate))"
        return text
    }
}

// MARK: - Full Timeline View
struct SiteTimelineView: View {
    let site: ConstructionSite
    @EnvironmentObject var sitesVM: SitesViewModel

    var events: [TimelineEvent] {
        sitesVM.timeline(for: site.id)
    }

    var body: some View {
        ZStack {
            AppBackground()

            if events.isEmpty {
                UFEmptyState(
                    icon: "clock.arrow.circlepath",
                    title: "No Timeline Events",
                    subtitle: "Activity on this site will appear here"
                )
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(events.indices, id: \.self) { idx in
                            HStack(alignment: .top, spacing: 16) {
                                // Timeline line + dot
                                VStack(spacing: 0) {
                                    if idx > 0 {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 2, height: 20)
                                    } else {
                                        Spacer().frame(height: 20)
                                    }

                                    ZStack {
                                        Circle()
                                            .fill(events[idx].type.color)
                                            .frame(width: 36, height: 36)
                                            .shadow(color: events[idx].type.color.opacity(0.4), radius: 4, x: 0, y: 2)
                                        Image(systemName: events[idx].type.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }

                                    if idx < events.count - 1 {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 2)
                                            .frame(maxHeight: .infinity)
                                    }
                                }
                                .frame(width: 36)

                                // Content
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(events[idx].title)
                                            .font(UFFont.headline(14))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(DateFormatter.ufShort.string(from: events[idx].date))
                                            .font(UFFont.caption(11))
                                            .foregroundColor(.secondary)
                                    }
                                    Text(events[idx].description)
                                        .font(UFFont.caption(13))
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)

                                    Text(DateFormatter.ufTime.string(from: events[idx].date))
                                        .font(UFFont.caption(10))
                                        .foregroundColor(.secondary.opacity(0.7))
                                }
                                .padding(.vertical, 14)
                                .padding(.trailing, 16)
                            }
                            .padding(.leading, 20)
                        }
                        Color.clear.frame(height: 80)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
    }
}
