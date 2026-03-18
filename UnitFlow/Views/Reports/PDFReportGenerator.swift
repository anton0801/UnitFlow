import UIKit
import SwiftUI

// MARK: - Report configuration
struct ReportConfig {
    var periodStart: Date
    var periodEnd: Date
    var includeCover: Bool = true
    var includeProgress: Bool = true
    var includeStages: Bool = true
    var includePhotos: Bool = true
    var includeIssues: Bool = true
    var includeAttendance: Bool = false
    var includeMaterials: Bool = false
    var photosPerPage: Int = 4  // 2, 4, or 6
}

// MARK: - Branding settings (stored in UserDefaults)
struct ReportBranding {
    var companyName: String
    var accentColorHex: String
    var footerText: String
    var showPoweredBy: Bool
    var logoData: Data?

    var accentUIColor: UIColor {
        UIColor(hex: accentColorHex.isEmpty ? "#1E40AF" : accentColorHex)
    }

    var accentColor: Color {
        Color(hex: accentColorHex.isEmpty ? "#1E40AF" : accentColorHex)
    }

    static func load() -> ReportBranding {
        let ud = UserDefaults.standard
        return ReportBranding(
            companyName: ud.string(forKey: "branding_company") ?? "",
            accentColorHex: ud.string(forKey: "branding_accent") ?? "#1E40AF",
            footerText: ud.string(forKey: "branding_footer") ?? "Confidential — for client use only",
            showPoweredBy: ud.bool(forKey: "branding_showPoweredBy"),
            logoData: ud.data(forKey: "branding_logo")
        )
    }

    func save() {
        let ud = UserDefaults.standard
        ud.set(companyName, forKey: "branding_company")
        ud.set(accentColorHex, forKey: "branding_accent")
        ud.set(footerText, forKey: "branding_footer")
        ud.set(showPoweredBy, forKey: "branding_showPoweredBy")
        ud.set(logoData, forKey: "branding_logo")
    }
}

// MARK: - Main generator
class PDFReportGenerator: ObservableObject {
    @Published var progress: Double = 0
    @Published var isGenerating = false
    @Published var generatedURL: URL? = nil
    @Published var error: String? = nil

    private let pageRect = CGRect(x: 0, y: 0, width: PDFLayout.pageWidth, height: PDFLayout.pageHeight)

    func generate(
        site: ConstructionSite,
        photos: [SitePhoto],
        issues: [Issue],
        config: ReportConfig,
        branding: ReportBranding,
        userName: String
    ) async {
        await MainActor.run {
            isGenerating = true
            progress = 0
            error = nil
        }

        let data = await Task.detached(priority: .userInitiated) { [weak self] () -> Data? in
            guard let self = self else { return nil }
            let renderer = UIGraphicsPDFRenderer(bounds: self.pageRect)
            let pdfData = renderer.pdfData { ctx in
                // Page 1 — Cover
                if config.includeCover {
                    ctx.beginPage()
                    self.drawCoverPage(ctx: ctx.cgContext, site: site, config: config, branding: branding, userName: userName)
                    Task { await MainActor.run { self.progress = 15 } }
                }
                // Page 2 — Executive Summary
                if config.includeProgress {
                    ctx.beginPage()
                    self.drawSummaryPage(ctx: ctx.cgContext, site: site, issues: issues, config: config, branding: branding)
                    Task { await MainActor.run { self.progress = 30 } }
                }
                // Page 3 — Stages
                if config.includeStages {
                    ctx.beginPage()
                    self.drawStagesPage(ctx: ctx.cgContext, site: site, branding: branding)
                    Task { await MainActor.run { self.progress = 45 } }
                }
                // Photo pages
                if config.includePhotos {
                    let filtered = photos.filter { $0.date >= config.periodStart && $0.date <= config.periodEnd }
                    let chunks = filtered.chunked(into: config.photosPerPage)
                    for (i, chunk) in chunks.enumerated() {
                        ctx.beginPage()
                        self.drawPhotoPage(ctx: ctx.cgContext, photos: chunk, pageNum: i + 1, config: config, branding: branding)
                        let p = 45.0 + Double(i + 1) / max(Double(chunks.count), 1) * 30.0
                        Task { await MainActor.run { self.progress = p } }
                    }
                }
                // Issues page
                if config.includeIssues {
                    let open = issues.filter { $0.status != .resolved }
                    ctx.beginPage()
                    self.drawIssuesPage(ctx: ctx.cgContext, issues: open, branding: branding)
                    Task { await MainActor.run { self.progress = 90 } }
                }
                // Last page — Footer
                ctx.beginPage()
                self.drawFooterPage(ctx: ctx.cgContext, branding: branding)
                Task { await MainActor.run { self.progress = 100 } }
            }
            return pdfData
        }.value

        guard let pdfData = data else {
            await MainActor.run { error = "Failed to generate PDF"; isGenerating = false }
            return
        }

        // Save to Documents
        let filename = "SiteReport_\(site.name.replacingOccurrences(of: " ", with: "_"))_\(Self.dateStamp()).pdf"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)

        do {
            try pdfData.write(to: url)
            await MainActor.run {
                generatedURL = url
                progress = 100
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isGenerating = false
            }
        }
    }

    private static func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: Date())
    }

    // MARK: - Page 1: Cover
    private func drawCoverPage(ctx: CGContext, site: ConstructionSite, config: ReportConfig, branding: ReportBranding, userName: String) {
        // Hero photo or gradient background
        if let photoData = site.photoData, let hero = UIImage(data: photoData) {
            pdfDrawImage(hero, in: pageRect, cornerRadius: 0, contentMode: .scaleAspectFill)
        } else {
            pdfDrawGradient(ctx: ctx, from: UIColor(hex: "#1A1A2E"), to: UIColor(hex: "#0D0D1A"), in: pageRect)
        }

        // Dark gradient overlay (bottom to top over bottom 70%)
        let overlayRect = CGRect(x: 0, y: pageRect.height * 0.28, width: pageRect.width, height: pageRect.height * 0.72)
        pdfDrawGradient(ctx: ctx, from: UIColor.black.withAlphaComponent(0.05), to: UIColor.black.withAlphaComponent(0.82), in: overlayRect)

        // Company logo (top-left)
        if let logoData = branding.logoData, let logo = UIImage(data: logoData) {
            pdfDrawImage(logo, in: CGRect(x: 28, y: 28, width: 48, height: 48), cornerRadius: 8)
        }

        // Company name next to logo
        if !branding.companyName.isEmpty {
            pdfDrawText(
                branding.companyName,
                in: CGRect(x: 86, y: 40, width: 200, height: 24),
                font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                color: UIColor.white.withAlphaComponent(0.9)
            )
        }

        // Report title
        pdfDrawText(
            "Site Progress Report",
            in: CGRect(x: PDFLayout.marginH, y: 440, width: PDFLayout.contentWidth, height: 36),
            font: UIFont.systemFont(ofSize: 28, weight: .semibold),
            color: .white
        )

        // Site name
        pdfDrawText(
            site.name,
            in: CGRect(x: PDFLayout.marginH, y: 484, width: PDFLayout.contentWidth, height: 30),
            font: UIFont.systemFont(ofSize: 22, weight: .regular),
            color: .white
        )

        // Address
        pdfDrawText(
            site.address,
            in: CGRect(x: PDFLayout.marginH, y: 520, width: PDFLayout.contentWidth, height: 20),
            font: UIFont.systemFont(ofSize: 14),
            color: UIColor.white.withAlphaComponent(0.7)
        )

        // Report period
        let periodStr = "\(DateFormatter.ufDate.string(from: config.periodStart)) – \(DateFormatter.ufDate.string(from: config.periodEnd))"
        pdfDrawText(
            periodStr,
            in: CGRect(x: PDFLayout.marginH, y: 548, width: PDFLayout.contentWidth, height: 18),
            font: UIFont.systemFont(ofSize: 13),
            color: UIColor.white.withAlphaComponent(0.6)
        )

        // Bottom: prepared by (left) + date generated (right)
        let preparedBy = "Prepared by \(userName)"
        pdfDrawText(
            preparedBy,
            in: CGRect(x: PDFLayout.marginH, y: 800, width: 250, height: 16),
            font: UIFont.systemFont(ofSize: 12),
            color: UIColor.white.withAlphaComponent(0.7)
        )
        let dateStr = DateFormatter.ufDate.string(from: Date())
        pdfDrawText(
            dateStr,
            in: CGRect(x: PDFLayout.marginH + 250, y: 800, width: 245, height: 16),
            font: UIFont.systemFont(ofSize: 12),
            color: UIColor.white.withAlphaComponent(0.7),
            alignment: .right
        )
    }

    // MARK: - Page 2: Executive Summary
    private func drawSummaryPage(ctx: CGContext, site: ConstructionSite, issues: [Issue], config: ReportConfig, branding: ReportBranding) {
        pdfDrawHeaderBar(title: "EXECUTIVE SUMMARY", y: PDFLayout.marginV, color: branding.accentUIColor)

        let doneStages = site.stages.filter { $0.status == .done }.count
        let totalStages = site.stages.count
        let openIssues = issues.filter { $0.status != .resolved }.count
        let cal = Calendar.current
        let daysRemaining = cal.dateComponents([.day], from: Date(), to: site.plannedEndDate).day ?? 0

        // 4 metric cards in 2×2 grid
        let cardW: CGFloat = (PDFLayout.contentWidth - 16) / 2
        let cardH: CGFloat = 90
        let cardY: CGFloat = PDFLayout.marginV + 50

        pdfDrawMetricCard(
            in: CGRect(x: PDFLayout.contentX, y: cardY, width: cardW, height: cardH),
            title: "Overall Progress", value: "\(Int(site.progressPercent))%",
            accentColor: branding.accentUIColor
        )
        pdfDrawMetricCard(
            in: CGRect(x: PDFLayout.contentX + cardW + 16, y: cardY, width: cardW, height: cardH),
            title: "Stages Complete", value: "\(doneStages) of \(totalStages)",
            accentColor: UIColor(hex: "#16A34A")
        )
        pdfDrawMetricCard(
            in: CGRect(x: PDFLayout.contentX, y: cardY + cardH + 12, width: cardW, height: cardH),
            title: "Open Issues", value: "\(openIssues)",
            accentColor: openIssues == 0 ? UIColor(hex: "#16A34A") : UIColor(hex: "#EF476F")
        )
        pdfDrawMetricCard(
            in: CGRect(x: PDFLayout.contentX + cardW + 16, y: cardY + cardH + 12, width: cardW, height: cardH),
            title: "Days Remaining", value: "\(max(daysRemaining, 0))",
            accentColor: UIColor(hex: "#F59E0B")
        )

        // Large progress bar
        let barY: CGFloat = cardY + cardH * 2 + 28
        pdfDrawText("Overall Progress", in: CGRect(x: PDFLayout.contentX, y: barY, width: PDFLayout.contentWidth, height: 16), font: UIFont.systemFont(ofSize: 12, weight: .semibold), color: .label)
        pdfDrawProgressBar(
            progress: site.progressPercent,
            in: CGRect(x: PDFLayout.contentX, y: barY + 22, width: PDFLayout.contentWidth, height: 14),
            fillColor: branding.accentUIColor
        )
        pdfDrawText(
            "Started: \(DateFormatter.ufDate.string(from: site.startDate))    Planned End: \(DateFormatter.ufDate.string(from: site.plannedEndDate))",
            in: CGRect(x: PDFLayout.contentX, y: barY + 42, width: PDFLayout.contentWidth, height: 14),
            font: UIFont.systemFont(ofSize: 10),
            color: .secondaryLabel
        )
        pdfDrawText(
            "\(Int(site.progressPercent))% complete",
            in: CGRect(x: PDFLayout.contentX, y: barY + 42, width: PDFLayout.contentWidth, height: 14),
            font: UIFont.systemFont(ofSize: 10, weight: .bold),
            color: branding.accentUIColor,
            alignment: .right
        )

        // Site details table
        let tableY = barY + 70
        pdfDrawText("Site Details", in: CGRect(x: PDFLayout.contentX, y: tableY, width: PDFLayout.contentWidth, height: 18), font: UIFont.systemFont(ofSize: 13, weight: .semibold), color: .label)
        pdfDrawSeparator(at: tableY + 20)

        let rows: [(String, String)] = [
            ("Client",        site.clientName),
            ("Address",       site.address),
            ("Site Type",     site.siteType.rawValue),
            ("Foreman",       site.responsiblePerson),
            ("Report Period", "\(DateFormatter.ufDate.string(from: config.periodStart)) – \(DateFormatter.ufDate.string(from: config.periodEnd))")
        ]
        for (i, row) in rows.enumerated() {
            pdfDrawTableRow(label: row.0, value: row.1, y: tableY + 24 + CGFloat(i) * 24, isAlt: i.isMultiple(of: 2))
        }
    }

    // MARK: - Page 3: Stages
    private func drawStagesPage(ctx: CGContext, site: ConstructionSite, branding: ReportBranding) {
        pdfDrawHeaderBar(title: "CONSTRUCTION STAGES", y: PDFLayout.marginV, color: branding.accentUIColor)

        var y: CGFloat = PDFLayout.marginV + 50
        for stage in site.stages.sorted(by: { $0.order < $1.order }) {
            if y > PDFLayout.pageHeight - 80 { break }  // page overflow guard

            let rowH: CGFloat = 36
            let rowBg: UIColor = stage.order.isMultiple(of: 2) ? UIColor.systemGray6.withAlphaComponent(0.4) : .clear
            pdfFillRect(CGRect(x: PDFLayout.contentX, y: y, width: PDFLayout.contentWidth, height: rowH), color: rowBg, cornerRadius: 6)

            // Stage name
            pdfDrawText(
                stage.name,
                in: CGRect(x: PDFLayout.contentX + 8, y: y + 10, width: 130, height: 18),
                font: UIFont.systemFont(ofSize: 12, weight: .medium),
                color: .label
            )

            // Status badge
            let (badgeBg, badgeText) = stageBadge(stage.status)
            _ = pdfDrawBadge(
                text: badgeText,
                at: CGPoint(x: PDFLayout.contentX + 148, y: y + 9),
                bgColor: badgeBg.withAlphaComponent(0.15),
                textColor: badgeBg,
                font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            )

            // Progress bar
            let barX = PDFLayout.contentX + 240
            let barW: CGFloat = PDFLayout.contentWidth - 295
            pdfDrawProgressBar(
                progress: stage.progressPercent,
                in: CGRect(x: barX, y: y + 13, width: barW, height: 10),
                fillColor: badgeBg
            )

            // Percentage
            pdfDrawText(
                "\(Int(stage.progressPercent))%",
                in: CGRect(x: PDFLayout.contentX + PDFLayout.contentWidth - 40, y: y + 10, width: 38, height: 16),
                font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                color: .secondaryLabel,
                alignment: .right
            )

            pdfDrawSeparator(at: y + rowH, color: UIColor.separator.withAlphaComponent(0.3))
            y += rowH + 2
        }

        // Footer note
        pdfDrawText(
            "As of \(DateFormatter.ufDate.string(from: Date()))",
            in: CGRect(x: PDFLayout.contentX, y: y + 10, width: PDFLayout.contentWidth, height: 14),
            font: UIFont.systemFont(ofSize: 10),
            color: .secondaryLabel
        )
    }

    private func stageBadge(_ status: WorkStage.StageStatus) -> (UIColor, String) {
        switch status {
        case .done:       return (UIColor(hex: "#16A34A"), "Done")
        case .inProgress: return (UIColor(hex: "#2563EB"), "In Progress")
        case .waiting:    return (UIColor(hex: "#F59E0B"), "Waiting")
        case .blocked:    return (UIColor(hex: "#DC2626"), "Blocked")
        case .notStarted: return (UIColor.secondaryLabel, "Not Started")
        }
    }

    // MARK: - Photo pages
    private func drawPhotoPage(ctx: CGContext, photos: [SitePhoto], pageNum: Int, config: ReportConfig, branding: ReportBranding) {
        pdfDrawHeaderBar(title: "PHOTO PROGRESS", y: PDFLayout.marginV, color: branding.accentUIColor)

        let perPage = config.photosPerPage
        let cols = perPage <= 2 ? 1 : 2
        let rows = Int(ceil(Double(perPage) / Double(cols)))
        let gap: CGFloat = 12
        let captionH: CGFloat = 36
        let cellW = (PDFLayout.contentWidth - CGFloat(cols - 1) * gap) / CGFloat(cols)
        let cellH = (PDFLayout.pageHeight - PDFLayout.marginV - 44 - PDFLayout.marginV - CGFloat(rows - 1) * gap) / CGFloat(rows) - captionH

        for (i, photo) in photos.prefix(perPage).enumerated() {
            let col = i % cols
            let row = i / cols
            let x = PDFLayout.contentX + CGFloat(col) * (cellW + gap)
            let y = PDFLayout.marginV + 44 + CGFloat(row) * (cellH + captionH + gap)

            // Photo
            let photoRect = CGRect(x: x, y: y, width: cellW, height: cellH)
            if let img = UIImage(data: photo.imageData) {
                pdfFillRect(photoRect, color: UIColor.systemGray5, cornerRadius: 6)
                pdfDrawImage(img, in: photoRect, cornerRadius: 6, contentMode: .scaleAspectFill)
            } else {
                pdfFillRect(photoRect, color: UIColor.systemGray5, cornerRadius: 6)
                pdfDrawText("No Image", in: photoRect, font: UIFont.systemFont(ofSize: 12), color: .secondaryLabel, alignment: .center)
            }

            // Caption
            let capY = y + cellH + 4
            let caption = [photo.zone, photo.type.rawValue, DateFormatter.ufShort.string(from: photo.date)].filter { !$0.isEmpty }.joined(separator: " · ")
            pdfDrawText(caption, in: CGRect(x: x, y: capY, width: cellW, height: 14), font: UIFont.systemFont(ofSize: 9, weight: .medium), color: .secondaryLabel)
            if !photo.comment.isEmpty {
                pdfDrawText(photo.comment, in: CGRect(x: x, y: capY + 14, width: cellW, height: 14), font: UIFont.systemFont(ofSize: 9), color: UIColor.secondaryLabel.withAlphaComponent(0.8), lineBreakMode: .byTruncatingTail)
            }
        }
    }

    // MARK: - Issues page
    private func drawIssuesPage(ctx: CGContext, issues: [Issue], branding: ReportBranding) {
        pdfDrawHeaderBar(title: "ACTIVE ISSUES", y: PDFLayout.marginV, color: branding.accentUIColor)

        guard !issues.isEmpty else {
            // All clear
            pdfDrawText(
                "✓  No active issues — all clear",
                in: CGRect(x: PDFLayout.contentX, y: PDFLayout.marginV + 80, width: PDFLayout.contentWidth, height: 30),
                font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                color: UIColor(hex: "#16A34A"),
                alignment: .center
            )
            return
        }

        var y = PDFLayout.marginV + 54
        // Column headers
        let headerFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
        pdfDrawText("Severity", in: CGRect(x: PDFLayout.contentX, y: y, width: 60, height: 14), font: headerFont, color: .secondaryLabel)
        pdfDrawText("Title", in: CGRect(x: PDFLayout.contentX + 70, y: y, width: 220, height: 14), font: headerFont, color: .secondaryLabel)
        pdfDrawText("Zone", in: CGRect(x: PDFLayout.contentX + 300, y: y, width: 80, height: 14), font: headerFont, color: .secondaryLabel)
        pdfDrawText("Due", in: CGRect(x: PDFLayout.contentX + 390, y: y, width: 60, height: 14), font: headerFont, color: .secondaryLabel)
        pdfDrawSeparator(at: y + 16)
        y += 22

        for issue in issues {
            if y > PDFLayout.pageHeight - 80 { break }
            let rowH: CGFloat = 36
            // Alternating bg
            if issues.firstIndex(where: { $0.id == issue.id }).map({ $0.isMultiple(of: 2) }) ?? false {
                pdfFillRect(CGRect(x: PDFLayout.contentX, y: y, width: PDFLayout.contentWidth, height: rowH), color: UIColor.systemGray6.withAlphaComponent(0.4))
            }

            let sevColor = severityUIColor(issue.severity)
            // Severity dot + label
            pdfFillRect(CGRect(x: PDFLayout.contentX + 2, y: y + 14, width: 6, height: 6), color: sevColor, cornerRadius: 3)
            pdfDrawText(
                issue.severity.rawValue.uppercased(),
                in: CGRect(x: PDFLayout.contentX + 12, y: y + 10, width: 52, height: 14),
                font: UIFont.systemFont(ofSize: 9, weight: .bold),
                color: sevColor
            )

            // Title
            pdfDrawText(
                issue.title,
                in: CGRect(x: PDFLayout.contentX + 70, y: y + 4, width: 220, height: 14),
                font: UIFont.systemFont(ofSize: 11, weight: .medium),
                color: .label
            )
            pdfDrawText(
                issue.category.rawValue,
                in: CGRect(x: PDFLayout.contentX + 70, y: y + 20, width: 220, height: 12),
                font: UIFont.systemFont(ofSize: 9),
                color: .secondaryLabel
            )

            // Zone
            pdfDrawText(issue.zone, in: CGRect(x: PDFLayout.contentX + 300, y: y + 10, width: 80, height: 14), font: UIFont.systemFont(ofSize: 10), color: .label)

            // Due date
            if let due = issue.deadline {
                pdfDrawText(
                    DateFormatter.ufShort.string(from: due),
                    in: CGRect(x: PDFLayout.contentX + 390, y: y + 10, width: 60, height: 14),
                    font: UIFont.systemFont(ofSize: 10),
                    color: .label
                )
            }

            pdfDrawSeparator(at: y + rowH, color: UIColor.separator.withAlphaComponent(0.25))
            y += rowH + 2
        }
    }

    private func severityUIColor(_ severity: Issue.Severity) -> UIColor {
        switch severity {
        case .low:      return UIColor(hex: "#16A34A")
        case .medium:   return UIColor(hex: "#F59E0B")
        case .high:     return UIColor(hex: "#FF6B35")
        case .critical: return UIColor(hex: "#EF476F")
        }
    }

    // MARK: - Last page: Footer
    private func drawFooterPage(ctx: CGContext, branding: ReportBranding) {
        pdfDrawHeaderBar(title: "REPORT SUMMARY", y: PDFLayout.marginV, color: branding.accentUIColor)

        let centerY = PDFLayout.pageHeight / 2 - 60

        if branding.showPoweredBy {
            pdfDrawText(
                "This report was automatically generated by Site Flow",
                in: CGRect(x: PDFLayout.contentX, y: centerY, width: PDFLayout.contentWidth, height: 20),
                font: UIFont.systemFont(ofSize: 13),
                color: .secondaryLabel,
                alignment: .center
            )
        }

        pdfDrawSeparator(at: centerY + 30, color: UIColor.separator)

        if !branding.companyName.isEmpty {
            pdfDrawText(
                branding.companyName,
                in: CGRect(x: PDFLayout.contentX, y: centerY + 44, width: PDFLayout.contentWidth, height: 20),
                font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                color: .label,
                alignment: .center
            )
        }

        let footerText = branding.footerText.isEmpty ? "Confidential — for client use only" : branding.footerText
        pdfDrawText(
            footerText,
            in: CGRect(x: PDFLayout.contentX, y: centerY + 70, width: PDFLayout.contentWidth, height: 18),
            font: UIFont.systemFont(ofSize: 11),
            color: .secondaryLabel,
            alignment: .center
        )

        // Page number at bottom
        pdfDrawText(
            "Generated \(DateFormatter.ufDate.string(from: Date()))",
            in: CGRect(x: PDFLayout.contentX, y: PDFLayout.pageHeight - 40, width: PDFLayout.contentWidth, height: 14),
            font: UIFont.systemFont(ofSize: 9),
            color: .tertiaryLabel,
            alignment: .center
        )
    }
}

// MARK: - Array chunking helper
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: Swift.max(size, 1)).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
