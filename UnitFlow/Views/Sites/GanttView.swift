import SwiftUI

// MARK: - Container (entry point used by SiteStagesTab)
struct GanttContainerView: View {
    let site: ConstructionSite
    @EnvironmentObject var sitesVM: SitesViewModel
    @StateObject private var vm = StageTimelineViewModel()
    @State private var showAddStage = false

    var currentSite: ConstructionSite {
        sitesVM.sites.first(where: { $0.id == site.id }) ?? site
    }

    var body: some View {
        GanttChartView(vm: vm, showAddStage: $showAddStage)
            .onAppear {
                vm.setup(site: currentSite) { stageId, start, end in
                    sitesVM.updateStageSchedule(
                        siteId: site.id,
                        stageId: stageId,
                        startDate: start,
                        endDate: end
                    )
                }
            }
            .onReceive(sitesVM.$sites) { sites in
                if let updated = sites.first(where: { $0.id == site.id }) {
                    vm.reload(from: updated)
                }
            }
            .sheet(isPresented: $showAddStage) {
                AddStageFromGanttSheet(siteId: site.id)
                    .environmentObject(sitesVM)
            }
    }
}

// MARK: - Main chart view
struct GanttChartView: View {
    @ObservedObject var vm: StageTimelineViewModel
    @Binding var showAddStage: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnyBarDragging = false
    @State private var scrollToToday = false
    @State private var baseDayWidthForPinch: CGFloat = 14

    var containerWidth: CGFloat { UIScreen.main.bounds.width }

    var columnBg: Color {
        colorScheme == .dark ? Color(hex: "#1E1E2E") : Color.white
    }

    var totalChartHeight: CGFloat {
        vm.headerHeight + CGFloat(vm.stages.count) * vm.rowHeight + 60
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Toolbar ──────────────────────────────────────────────
            GanttToolbarView(
                vm: vm,
                onToday: { scrollToToday = true },
                onFitAll: { vm.fitAll(containerWidth: containerWidth) },
                onAddStage: { showAddStage = true }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(columnBg)
            
            Divider()
            
            // ── Chart or empty state ──────────────────────────────────
            if vm.stages.isEmpty {
                GanttEmptyStateView { showAddStage = true }
            } else {
                let chartHeight = totalChartHeight
                ZStack(alignment: .topLeading) {
                    // === Scrollable chart ===
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            ZStack(alignment: .topLeading) {
                                // Row backgrounds + grid
                                GanttGridBackground(
                                    vm: vm,
                                    totalHeight: totalChartHeight,
                                    showWeekends: vm.showWeekends
                                )
                                
                                // Header + bar rows
                                VStack(spacing: 0) {
                                    // Header spacer (left column covered by overlay)
                                    Color.clear
                                        .frame(width: vm.leftColumnWidth + vm.totalWidth, height: vm.headerHeight)
                                    
                                    Divider().frame(width: vm.leftColumnWidth + vm.totalWidth)
                                    
                                    ForEach(vm.stages) { stage in
                                        GanttBarRowView(
                                            stage: stage,
                                            vm: vm,
                                            isAnyDragging: $isAnyBarDragging
                                        )
                                        .frame(width: vm.leftColumnWidth + vm.totalWidth, height: vm.rowHeight)
                                    }
                                    Color.clear.frame(height: 60)
                                }
                                
                                // Timeline header
                                HStack(spacing: 0) {
                                    Color.clear.frame(width: vm.leftColumnWidth, height: vm.headerHeight)
                                    GanttTimelineHeaderView(vm: vm)
                                        .frame(width: vm.totalWidth, height: vm.headerHeight)
                                }
                                
                                // Today line
                                if vm.showTodayLine {
                                    GanttTodayLine(
                                        vm: vm,
                                        totalHeight: totalChartHeight
                                    )
                                }
                                
                                // Invisible scroll anchor at today
                                Color.clear.frame(width: 1, height: 1)
                                    .id("todayAnchor")
                                    .offset(x: vm.leftColumnWidth + vm.todayX)
                            }
                            .frame(
                                width: vm.leftColumnWidth + vm.totalWidth,
                                height: totalChartHeight
                            )
                        }
                        .scrollDisabled(isAnyBarDragging)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo("todayAnchor", anchor: .center)
                                }
                            }
                        }
                        .onChange(of: scrollToToday) { val in
                            if val {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    proxy.scrollTo("todayAnchor", anchor: .center)
                                }
                                scrollToToday = false
                            }
                        }
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale in
                                vm.setDayWidth(baseDayWidthForPinch * scale)
                            }
                            .onEnded { scale in
                                baseDayWidthForPinch = vm.dayWidth
                                vm.saveDayWidth()
                            }
                    )
                    .onAppear { baseDayWidthForPinch = vm.dayWidth }
                    
                    // === Fixed left column ===
                    GanttLeftColumnView(vm: vm, onAddStage: { showAddStage = true })
                        .allowsHitTesting(true)
                }
            }

            // Conflict warning toast
            if let warning = vm.conflictWarning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(UFColors.warning)
                        .font(.system(size: 14))
                    Text(warning)
                        .font(UFFont.caption(12))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(UFColors.warning.opacity(0.12))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.conflictWarning != nil)
            }
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Toolbar
struct GanttToolbarView: View {
    @ObservedObject var vm: StageTimelineViewModel
    let onToday: () -> Void
    let onFitAll: () -> Void
    let onAddStage: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToday) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.to.line")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Today")
                        .font(UFFont.caption(13))
                }
                .foregroundColor(UFColors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(UFColors.primary.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            // Zoom indicator
            Text("\(Int(vm.dayWidth * 7))pt/wk")
                .font(UFFont.mono(11))
                .foregroundColor(.secondary)

            Button(action: onFitAll) {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(UFColors.primary)
                    .padding(8)
                    .background(UFColors.primary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())

            Menu {
                Toggle("Show Today Line", isOn: $vm.showTodayLine)
                Toggle("Show Dependencies", isOn: $vm.showDependencies)
                Toggle("Shade Weekends", isOn: $vm.showWeekends)
                Divider()
                Button { onAddStage() } label: {
                    Label("Add Stage", systemImage: "plus.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Timeline header (months + weeks)
struct GanttTimelineHeaderView: View {
    @ObservedObject var vm: StageTimelineViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Canvas { ctx, size in
            let headerBg = colorScheme == .dark ? UIColor(hex: "#1E1E2E") : UIColor.white
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(headerBg)))

            let separatorColor = Color.gray.opacity(0.2)
            let monthFg = Color.primary
            let weekFg = Color.secondary.opacity(0.7)

            // Month labels + separators
            for month in vm.months {
                let x = month.x
                // Vertical separator
                ctx.fill(
                    Path(CGRect(x: x, y: 4, width: 0.5, height: size.height - 8)),
                    with: .color(separatorColor)
                )
                // Month label
                var txt = AttributedString(month.label)
                txt.font = .system(size: 11, weight: .semibold, design: .rounded)
                txt.foregroundColor = monthFg
                ctx.draw(Text(txt), at: CGPoint(x: x + 6, y: 8), anchor: .topLeading)
            }

            // Week markers
            let weekFmt = DateFormatter()
            weekFmt.dateFormat = "d"
            for week in vm.weeks where week.x >= 0 && week.x < vm.totalWidth {
                let x = week.x
                // Tick
                ctx.fill(
                    Path(CGRect(x: x, y: size.height - 14, width: 0.5, height: 6)),
                    with: .color(separatorColor)
                )
                // Day number
                var txt = AttributedString(weekFmt.string(from: week.date))
                txt.font = .system(size: 9, weight: .regular)
                txt.foregroundColor = weekFg
                ctx.draw(Text(txt), at: CGPoint(x: x + 2, y: size.height - 16), anchor: .topLeading)
            }
        }
        .frame(width: vm.totalWidth, height: vm.headerHeight)
    }
}

// MARK: - Grid background (row shading + weekend columns)
struct GanttGridBackground: View {
    @ObservedObject var vm: StageTimelineViewModel
    let totalHeight: CGFloat
    let showWeekends: Bool

    var body: some View {
        Canvas { ctx, size in
            let rowBg1 = Color.gray.opacity(0.03)
            let rowBg2 = Color.clear
            let weekendBg = Color.gray.opacity(0.06)
            let gridLine = Color.gray.opacity(0.08)

            // Alternating row backgrounds
            for (i, _) in vm.stages.enumerated() {
                let y = vm.headerHeight + 1 + CGFloat(i) * vm.rowHeight
                let rowRect = CGRect(x: vm.leftColumnWidth, y: y, width: vm.totalWidth, height: vm.rowHeight)
                ctx.fill(Path(rowRect), with: .color(i.isMultiple(of: 2) ? rowBg1 : rowBg2))
            }

            // Weekend shading
            if showWeekends {
                let cal = Calendar.current
                var current = vm.visibleStart
                while current < vm.visibleEnd {
                    let weekday = cal.component(.weekday, from: current)
                    if weekday == 7 || weekday == 1 {
                        let x = vm.leftColumnWidth + vm.xPosition(for: current)
                        let rect = CGRect(x: x, y: vm.headerHeight, width: vm.dayWidth, height: totalHeight - vm.headerHeight)
                        ctx.fill(Path(rect), with: .color(weekendBg))
                    }
                    current = cal.date(byAdding: .day, value: 1, to: current) ?? current
                }
            }

            // Horizontal row separators
            for i in 0...vm.stages.count {
                let y = vm.headerHeight + 1 + CGFloat(i) * vm.rowHeight
                ctx.fill(
                    Path(CGRect(x: vm.leftColumnWidth, y: y, width: vm.totalWidth, height: 0.5)),
                    with: .color(gridLine)
                )
            }
        }
        .frame(width: vm.leftColumnWidth + vm.totalWidth, height: totalHeight)
    }
}

// MARK: - Today line
struct GanttTodayLine: View {
    @ObservedObject var vm: StageTimelineViewModel
    let totalHeight: CGFloat

    var body: some View {
        let x = vm.leftColumnWidth + vm.todayX

        ZStack(alignment: .top) {
            // Line
            Rectangle()
                .fill(Color(hex: "#EF4444").opacity(0.85))
                .frame(width: 1.5, height: totalHeight - vm.headerHeight)
                .offset(x: x - 0.75, y: vm.headerHeight + 1)

            // "Today" pill at top
            Text("Today")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(hex: "#EF4444"))
                .clipShape(Capsule())
                .offset(x: x - 20, y: vm.headerHeight - 18)
        }
        .frame(width: vm.leftColumnWidth + vm.totalWidth, height: totalHeight)
    }
}

// MARK: - Single stage bar row
struct GanttBarRowView: View {
    let stage: WorkStage
    @ObservedObject var vm: StageTimelineViewModel
    @Binding var isAnyDragging: Bool

    @State private var dragOffset: CGFloat = 0
    @State private var isThisDragging = false
    @State private var dragMode: DragMode = .move
    @State private var showPopover = false

    enum DragMode { case move, startEdge, endEdge }

    var effectiveStart: Date { vm.effectiveStartDate(for: stage) }
    var effectiveEnd: Date { vm.effectiveEndDate(for: stage) }
    var bx: CGFloat { vm.barStartX(for: stage) }
    var bw: CGFloat { vm.barWidth(for: stage) }
    let barH: CGFloat = 28

    var currentDragStart: Date {
        let days = Int(round(dragOffset / vm.dayWidth))
        return Calendar.current.date(byAdding: .day, value: days, to: effectiveStart) ?? effectiveStart
    }
    var currentDragEnd: Date {
        let days = Int(round(dragOffset / vm.dayWidth))
        return Calendar.current.date(byAdding: .day, value: days, to: effectiveEnd) ?? effectiveEnd
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Highlight row when dragging
            if isThisDragging {
                Rectangle()
                    .fill(stage.status.ganttColor.opacity(0.06))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Ghost bar (original position) while dragging
            if isThisDragging {
                RoundedRectangle(cornerRadius: barH / 2)
                    .strokeBorder(
                        stage.status.ganttColor.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                    )
                    .frame(width: bw, height: barH)
                    .offset(x: bx, y: (vm.rowHeight - barH) / 2)
            }

            // The actual bar
            stageBar
                .offset(
                    x: bx + (isThisDragging ? dragOffset : 0),
                    y: (vm.rowHeight - barH) / 2
                )

            // Drag tooltip
            if isThisDragging {
                dragTooltipView
                    .offset(
                        x: max(bx + dragOffset + bw / 2 - 60, vm.leftColumnWidth + 4),
                        y: (vm.rowHeight - barH) / 2 - 30
                    )
            }
        }
        .overlay(
            Group {
                if showPopover {
                    GanttStagePopoverView(stage: stage, vm: vm, isShowing: $showPopover)
                        .offset(x: min(bx, vm.leftColumnWidth + vm.totalWidth - 220), y: vm.rowHeight)
                        .zIndex(200)
                }
            }
        )
        .contentShape(Rectangle())
    }

    // MARK: Bar rendering
    @ViewBuilder
    var stageBar: some View {
        ZStack(alignment: .leading) {
            barBackground
                .frame(width: bw, height: barH)
                .clipShape(Capsule())
                .scaleEffect(isThisDragging ? CGSize(width: 1.0, height: 1.06) : .init(width: 1, height: 1))
                .shadow(
                    color: isThisDragging ? stage.status.ganttColor.opacity(0.5) : .clear,
                    radius: 8, x: 0, y: 4
                )
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isThisDragging)

            // Icons / labels inside bar
            HStack(spacing: 4) {
                if bw > 50 {
                    Text(stage.name)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .padding(.leading, 8)
                }
                Spacer()
                if stage.status == .done && bw > 32 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.trailing, 6)
                } else if stage.status == .blocked && bw > 32 {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.trailing, 6)
                }
            }
            .frame(width: bw)

            // Left edge drag handle
            edgeHandle(isLeft: true)
                .frame(width: 16, height: barH)

            // Right edge drag handle
            edgeHandle(isLeft: false)
                .frame(width: 16, height: barH)
                .offset(x: bw - 16)
        }
        .frame(width: bw, height: barH)
        // Long press activates move-drag on center
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .onEnded { _ in activateDrag(mode: .move) }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    guard isThisDragging else { return }
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    guard isThisDragging else { return }
                    commitDrag(translation: value.translation.width)
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showPopover.toggle()
            }
        }
    }

    @ViewBuilder
    var barBackground: some View {
        switch stage.status {
        case .done:
            LinearGradient(
                colors: [Color(hex: "#16A34A"), Color(hex: "#15803D")],
                startPoint: .leading, endPoint: .trailing
            )
        case .inProgress:
            let pct = CGFloat(min(max(stage.progressPercent / 100, 0), 1))
            ZStack(alignment: .leading) {
                // Remaining (hatched look via low opacity)
                Color(hex: "#2563EB").opacity(0.28)
                // Completed solid
                LinearGradient(
                    colors: [Color(hex: "#2563EB"), Color(hex: "#3B82F6")],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: bw * pct)
            }
        case .waiting:
            Color(hex: "#F59E0B").opacity(0.55)
        case .blocked:
            LinearGradient(
                colors: [Color(hex: "#DC2626"), Color(hex: "#B91C1C")],
                startPoint: .leading, endPoint: .trailing
            )
        case .notStarted:
            Color(hex: "#94A3B8").opacity(0.45)
        }
    }

    func edgeHandle(isLeft: Bool) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {} // absorb taps
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        if !isThisDragging {
                            activateDrag(mode: isLeft ? .startEdge : .endEdge)
                        }
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        guard isThisDragging else { return }
                        commitDrag(translation: value.translation.width)
                    }
            )
    }

    var dragTooltipView: some View {
        let cal = Calendar.current
        let dayDelta = Int(round(dragOffset / vm.dayWidth))
        let label: String
        switch dragMode {
        case .move:
            let s = cal.date(byAdding: .day, value: dayDelta, to: effectiveStart)!
            let e = cal.date(byAdding: .day, value: dayDelta, to: effectiveEnd)!
            let dur = cal.dateComponents([.day], from: s, to: e).day ?? 0
            label = "\(DateFormatter.ufShort.string(from: s)) → \(DateFormatter.ufShort.string(from: e)) (\(dur)d)"
        case .startEdge:
            let s = cal.date(byAdding: .day, value: dayDelta, to: effectiveStart)!
            label = "Start: \(DateFormatter.ufDate.string(from: s))"
        case .endEdge:
            let e = cal.date(byAdding: .day, value: dayDelta, to: effectiveEnd)!
            label = "End: \(DateFormatter.ufDate.string(from: e))"
        }
        return Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(UIColor.label).opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .fixedSize()
    }

    // MARK: Helpers
    private func activateDrag(mode: DragMode) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isThisDragging = true
            isAnyDragging = true
            dragMode = mode
        }
    }

    private func commitDrag(translation: CGFloat) {
        let dayDelta = Int(round(translation / vm.dayWidth))
        let cal = Calendar.current
        let newStart: Date
        let newEnd: Date
        switch dragMode {
        case .move:
            newStart = cal.date(byAdding: .day, value: dayDelta, to: effectiveStart) ?? effectiveStart
            newEnd   = cal.date(byAdding: .day, value: dayDelta, to: effectiveEnd) ?? effectiveEnd
        case .startEdge:
            newStart = cal.date(byAdding: .day, value: dayDelta, to: effectiveStart) ?? effectiveStart
            newEnd   = effectiveEnd
        case .endEdge:
            newStart = effectiveStart
            newEnd   = cal.date(byAdding: .day, value: dayDelta, to: effectiveEnd) ?? effectiveEnd
        }
        // Guard: end must be after start
        guard newEnd > newStart else {
            withAnimation { isThisDragging = false; isAnyDragging = false; dragOffset = 0 }
            return
        }
        vm.updateSchedule(stageId: stage.id, newStart: newStart, newEnd: newEnd)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            isThisDragging = false
            isAnyDragging = false
            dragOffset = 0
        }
    }
}

// MARK: - Left column (fixed overlay)
struct GanttLeftColumnView: View {
    @ObservedObject var vm: StageTimelineViewModel
    var onAddStage: (() -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme

    var columnBg: Color {
        colorScheme == .dark ? Color(hex: "#1E1E2E") : Color.white
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header cell with "+" button
            HStack {
                Text("Stage")
                    .font(UFFont.caption(11))
                    .foregroundColor(.secondary)
                Spacer()
                if let onAddStage = onAddStage {
                    Button(action: onAddStage) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(UFColors.primary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .frame(width: vm.leftColumnWidth, height: vm.headerHeight)
            .background(columnBg)

            Divider().frame(width: vm.leftColumnWidth)

            // Stage name cells
            ForEach(vm.stages) { stage in
                GanttLeftCellView(stage: stage, vm: vm)
                    .frame(width: vm.leftColumnWidth, height: vm.rowHeight)
                    .background(columnBg)
            }
        }
        .frame(width: vm.leftColumnWidth)
        // Subtle right shadow to separate from chart
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.1), radius: 5, x: 3, y: 0)
    }
}

// MARK: - Left cell (one stage name)
struct GanttLeftCellView: View {
    let stage: WorkStage
    @ObservedObject var vm: StageTimelineViewModel

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(stage.status.ganttColor)
                .frame(width: 6, height: 6)
            Text(stage.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Stage detail popover
struct GanttStagePopoverView: View {
    let stage: WorkStage
    @ObservedObject var vm: StageTimelineViewModel
    @Binding var isShowing: Bool

    var effectiveStart: Date { vm.effectiveStartDate(for: stage) }
    var effectiveEnd: Date { vm.effectiveEndDate(for: stage) }
    var duration: Int {
        Calendar.current.dateComponents([.day], from: effectiveStart, to: effectiveEnd).day ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(stage.status.ganttColor)
                    .frame(width: 8, height: 8)
                Text(stage.name)
                    .font(UFFont.headline(14))
                Spacer()
                Button {
                    withAnimation { isShowing = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Info rows
            VStack(alignment: .leading, spacing: 8) {
                popoverRow(label: "Status", value: stage.status.rawValue, valueColor: stage.status.ganttColor)
                popoverRow(label: "Start", value: DateFormatter.ufDate.string(from: effectiveStart))
                popoverRow(label: "End", value: DateFormatter.ufDate.string(from: effectiveEnd))
                popoverRow(label: "Duration", value: "\(duration) days")
                if stage.status == .inProgress {
                    popoverRow(label: "Progress", value: "\(Int(stage.progressPercent))%")
                }
            }
            .padding(12)
        }
        .frame(width: 210)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
    }

    func popoverRow(label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(label)
                .font(UFFont.caption(11))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(UFFont.caption(12))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Empty state
struct GanttEmptyStateView: View {
    let onAdd: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(UFColors.primary.opacity(0.5))
            Text("No Stages Yet")
                .font(UFFont.headline(18))
            Text("Add construction stages to see the timeline")
                .font(UFFont.body(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onAdd) {
                Text("+ Add First Stage")
                    .font(UFFont.headline(15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(UFColors.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Add Stage from Gantt sheet
struct AddStageFromGanttSheet: View {
    let siteId: UUID
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date())!
    @State private var status: WorkStage.StageStatus = .notStarted

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Stage Name") {
                            UFTextField(icon: "list.bullet.rectangle", placeholder: "e.g. Electrical Work", text: $name)
                        }
                        FormSection(title: "Dates") {
                            VStack(spacing: 0) {
                                DatePicker("Start", selection: $startDate, displayedComponents: .date)
                                    .padding(14)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                DatePicker("End", selection: $endDate, displayedComponents: .date)
                                    .padding(14)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        FormSection(title: "Status") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(WorkStage.StageStatus.allCases, id: \.self) { s in
                                        FilterPill(
                                            title: s.rawValue,
                                            isSelected: status == s,
                                            color: s.ganttColor
                                        ) { status = s }
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Stage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addStage() }
                        .font(UFFont.headline(15))
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addStage() {
        guard let idx = sitesVM.sites.firstIndex(where: { $0.id == siteId }) else {
            presentationMode.wrappedValue.dismiss()
            return
        }
        let newOrder = sitesVM.sites[idx].stages.map(\.order).max().map { $0 + 1 } ?? 0
        var stage = WorkStage(name: name.trimmingCharacters(in: .whitespaces), status: status, order: newOrder)
        stage.startDate = startDate
        stage.endDate = endDate
        sitesVM.sites[idx].stages.append(stage)
        sitesVM.updateSite(sitesVM.sites[idx])
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Gantt image exporter
struct GanttExporter {
    static func exportImage(vm: StageTimelineViewModel, siteName: String) -> UIImage? {
        let leftW: CGFloat = 120
        let rowH: CGFloat = 44
        let headerH: CGFloat = 50
        let totalWidth = leftW + vm.totalWidth
        let totalHeight = headerH + CGFloat(vm.stages.count) * rowH + 20

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight))
        return renderer.image { ctx in
            let cgCtx = ctx.cgContext
            // Background
            UIColor.systemBackground.setFill()
            cgCtx.fill(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))

            // Header bar
            UIColor.systemGray6.setFill()
            cgCtx.fill(CGRect(x: 0, y: 0, width: totalWidth, height: headerH))

            // Site name
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            siteName.draw(at: CGPoint(x: leftW + 8, y: 16), withAttributes: titleAttrs)

            // Left column header
            let colAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel
            ]
            "Stage".draw(at: CGPoint(x: 8, y: 18), withAttributes: colAttrs)

            // Month labels
            let monthAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.secondaryLabel
            ]
            for month in vm.months {
                let x = leftW + month.x
                month.label.draw(at: CGPoint(x: x + 4, y: 6), withAttributes: monthAttrs)
                // Separator
                UIColor.separator.setFill()
                cgCtx.fill(CGRect(x: x, y: 0, width: 0.5, height: headerH))
            }

            // Stage rows
            for (i, stage) in vm.stages.enumerated() {
                let y = headerH + CGFloat(i) * rowH

                // Row bg
                if i.isMultiple(of: 2) {
                    UIColor.systemGray6.withAlphaComponent(0.4).setFill()
                    cgCtx.fill(CGRect(x: 0, y: y, width: totalWidth, height: rowH))
                }

                // Stage name
                stage.name.draw(
                    at: CGPoint(x: 8, y: y + (rowH - 14) / 2),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.label
                    ]
                )

                // Bar
                let barX = leftW + vm.xPosition(for: vm.effectiveStartDate(for: stage))
                let barW = max(vm.barWidth(for: stage), 4)
                let barY = y + (rowH - 20) / 2
                let barRect = CGRect(x: barX, y: barY, width: barW, height: 20)

                cgCtx.saveGState()
                UIBezierPath(roundedRect: barRect, cornerRadius: 10).addClip()
                stage.status.ganttUIColor.setFill()
                cgCtx.fill(barRect)
                cgCtx.restoreGState()
            }

            // Today line
            UIColor.systemRed.withAlphaComponent(0.7).setFill()
            cgCtx.fill(CGRect(x: leftW + vm.todayX, y: 0, width: 1.5, height: totalHeight))

            // Left column separator
            UIColor.separator.setFill()
            cgCtx.fill(CGRect(x: leftW, y: 0, width: 0.5, height: totalHeight))
        }
    }
}

// MARK: - WorkStage status colour helpers
extension WorkStage.StageStatus {
    var ganttColor: Color {
        switch self {
        case .done:       return Color(hex: "#16A34A")
        case .inProgress: return Color(hex: "#2563EB")
        case .waiting:    return Color(hex: "#F59E0B")
        case .blocked:    return Color(hex: "#DC2626")
        case .notStarted: return Color(hex: "#94A3B8")
        }
    }

    var ganttUIColor: UIColor {
        switch self {
        case .done:       return UIColor(red: 0.086, green: 0.639, blue: 0.290, alpha: 1)
        case .inProgress: return UIColor(red: 0.145, green: 0.388, blue: 0.922, alpha: 1)
        case .waiting:    return UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1)
        case .blocked:    return UIColor(red: 0.863, green: 0.149, blue: 0.149, alpha: 1)
        case .notStarted: return UIColor(red: 0.580, green: 0.635, blue: 0.722, alpha: 1)
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: CGFloat
        switch hex.count {
        case 6:
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8)  & 0xFF) / 255
            b = CGFloat(int         & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
