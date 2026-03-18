import SwiftUI
import Combine

class StageTimelineViewModel: ObservableObject {

    // MARK: - Published state
    @Published var stages: [WorkStage] = []
    @Published var dayWidth: CGFloat = 14
    @Published var showDependencies: Bool = false
    @Published var showTodayLine: Bool = true
    @Published var showWeekends: Bool = false
    @Published var conflictWarning: String? = nil

    // MARK: - Constants
    let minDayWidth: CGFloat = 6
    let maxDayWidth: CGFloat = 30
    let leftColumnWidth: CGFloat = 120
    let headerHeight: CGFloat = 56
    let rowHeight: CGFloat = 52

    // MARK: - Private
    private(set) var projectStart: Date = Date()
    private(set) var projectEnd: Date = Date()
    private var siteId: UUID = UUID()
    private var updateCallback: ((UUID, Date, Date) -> Void)?

    // MARK: - Setup
    func setup(site: ConstructionSite, updateCallback: @escaping (UUID, Date, Date) -> Void) {
        self.siteId = site.id
        self.updateCallback = updateCallback
        self.projectStart = site.startDate
        self.projectEnd = site.plannedEndDate
        self.dayWidth = loadDayWidth(for: site.id)
        reload(from: site)
    }

    func reload(from site: ConstructionSite) {
        projectStart = site.startDate
        projectEnd = site.plannedEndDate
        stages = site.stages.sorted { $0.order < $1.order }
    }

    // MARK: - Date ↔ Position
    var visibleStart: Date {
        let cal = Calendar.current
        let earliest = stages.compactMap { $0.startDate }.min() ?? projectStart
        return cal.date(byAdding: .weekOfYear, value: -2, to: earliest) ?? earliest
    }

    var visibleEnd: Date {
        let cal = Calendar.current
        let latest = stages.compactMap { $0.endDate }.max() ?? projectEnd
        return cal.date(byAdding: .month, value: 2, to: latest) ?? latest
    }

    var totalDays: Int {
        max(Calendar.current.dateComponents([.day], from: visibleStart, to: visibleEnd).day ?? 90, 90)
    }

    var totalWidth: CGFloat { CGFloat(totalDays) * dayWidth }

    var todayX: CGFloat { xPosition(for: Date()) }

    func xPosition(for date: Date) -> CGFloat {
        let days = Calendar.current.dateComponents([.day], from: visibleStart, to: date).day ?? 0
        return CGFloat(days) * dayWidth
    }

    func date(forX x: CGFloat) -> Date {
        let days = Int(x / dayWidth)
        return Calendar.current.date(byAdding: .day, value: days, to: visibleStart) ?? visibleStart
    }

    // MARK: - Effective dates (fallback when stage has no dates)
    func effectiveStartDate(for stage: WorkStage) -> Date {
        if let d = stage.startDate { return d }
        let totalDays = max(Calendar.current.dateComponents([.day], from: projectStart, to: projectEnd).day ?? 30, 1)
        let daysPerStage = totalDays / max(stages.count, 1)
        return Calendar.current.date(byAdding: .day, value: stage.order * daysPerStage, to: projectStart) ?? projectStart
    }

    func effectiveEndDate(for stage: WorkStage) -> Date {
        if let d = stage.endDate { return d }
        let totalDays = max(Calendar.current.dateComponents([.day], from: projectStart, to: projectEnd).day ?? 30, 1)
        let daysPerStage = totalDays / max(stages.count, 1)
        return Calendar.current.date(byAdding: .day, value: (stage.order + 1) * daysPerStage, to: projectStart) ?? projectStart
    }

    func barStartX(for stage: WorkStage) -> CGFloat {
        leftColumnWidth + xPosition(for: effectiveStartDate(for: stage))
    }

    func barWidth(for stage: WorkStage) -> CGFloat {
        let start = xPosition(for: effectiveStartDate(for: stage))
        let end   = xPosition(for: effectiveEndDate(for: stage))
        return max(end - start, dayWidth * 1)
    }

    // MARK: - Header data
    struct MonthInfo: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let x: CGFloat
        let width: CGFloat
    }

    var months: [MonthInfo] {
        var result: [MonthInfo] = []
        var current = visibleStart
        let cal = Calendar.current
        // Align to start of month
        var comps = cal.dateComponents([.year, .month], from: current)
        comps.day = 1
        current = cal.date(from: comps) ?? current

        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"

        while current < visibleEnd {
            let x = xPosition(for: current)
            let nextMonth = cal.date(byAdding: .month, value: 1, to: current)!
            let width = xPosition(for: nextMonth) - x
            result.append(MonthInfo(date: current, label: fmt.string(from: current), x: x, width: width))
            current = nextMonth
        }
        return result
    }

    struct WeekInfo: Identifiable {
        let id = UUID()
        let date: Date
        let x: CGFloat
    }

    var weeks: [WeekInfo] {
        var result: [WeekInfo] = []
        let cal = Calendar.current
        // Start from first Monday on or after visibleStart
        var current = visibleStart
        let weekday = cal.component(.weekday, from: current)
        let daysToMon = weekday == 2 ? 0 : (9 - weekday) % 7
        current = cal.date(byAdding: .day, value: daysToMon, to: current) ?? current

        while current <= visibleEnd {
            let x = xPosition(for: current)
            if x >= 0 { result.append(WeekInfo(date: current, x: x)) }
            current = cal.date(byAdding: .weekOfYear, value: 1, to: current) ?? current
        }
        return result
    }

    // MARK: - Drag / Reschedule
    func updateSchedule(stageId: UUID, newStart: Date, newEnd: Date) {
        let snappedStart = Calendar.current.startOfDay(for: newStart)
        let snappedEnd   = Calendar.current.startOfDay(for: newEnd)

        // Update locally for immediate feedback
        if let idx = stages.firstIndex(where: { $0.id == stageId }) {
            stages[idx].startDate = snappedStart
            stages[idx].endDate   = snappedEnd
        }

        // Persist via callback
        updateCallback?(stageId, snappedStart, snappedEnd)

        // Conflict detection
        checkConflicts(movedId: stageId, newStart: snappedStart)
    }

    private func checkConflicts(movedId: UUID, newStart: Date) {
        guard let moved = stages.first(where: { $0.id == movedId }) else { return }
        for other in stages where other.id != movedId && other.order < moved.order {
            if let otherEnd = other.endDate, otherEnd > newStart {
                let warning = "\(moved.name) overlaps with \(other.name) — check dependencies"
                withAnimation {
                    conflictWarning = warning
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                    withAnimation { self?.conflictWarning = nil }
                }
                return
            }
        }
    }

    // MARK: - Zoom
    func setDayWidth(_ width: CGFloat) {
        dayWidth = max(minDayWidth, min(maxDayWidth, width))
    }

    func saveDayWidth() {
        UserDefaults.standard.set(Double(dayWidth), forKey: "ganttDayWidth_\(siteId)")
    }

    func fitAll(containerWidth: CGFloat) {
        let target = (containerWidth - leftColumnWidth) / CGFloat(max(totalDays, 1))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dayWidth = max(minDayWidth, min(maxDayWidth, target))
        }
        saveDayWidth()
    }

    private func loadDayWidth(for id: UUID) -> CGFloat {
        let stored = CGFloat(UserDefaults.standard.double(forKey: "ganttDayWidth_\(id)"))
        return stored < minDayWidth ? 14 : stored
    }
}
