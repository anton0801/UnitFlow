import Foundation
import SwiftUI
import Combine

class SitesViewModel: ObservableObject {
    @Published var sites: [ConstructionSite] = []
    @Published var selectedSite: ConstructionSite? = nil
    @Published var reports: [DailyReport] = []
    @Published var issues: [Issue] = []
    @Published var tasks: [SiteTask] = []
    @Published var photos: [SitePhoto] = []
    @Published var materials: [MaterialRequest] = []
    @Published var deliveries: [Delivery] = []
    @Published var documents: [SiteDocument] = []
    @Published var timeline: [TimelineEvent] = []
    
    private let sitesKey = "unitflow_sites"
    private let reportsKey = "unitflow_reports"
    private let issuesKey = "unitflow_issues"
    private let tasksKey = "unitflow_tasks"
    private let photosKey = "unitflow_photos"
    private let materialsKey = "unitflow_materials"
    private let deliveriesKey = "unitflow_deliveries"
    private let documentsKey = "unitflow_documents"
    private let timelineKey = "unitflow_timeline"
    
    init() {
        loadAll()
        if sites.isEmpty { seedDemoData() }
    }
    
    // MARK: - Sites CRUD
    func addSite(_ site: ConstructionSite) {
        var s = site
        s.stages = WorkStage.defaultStages()
        sites.append(s)
        saveSites()
        addTimelineEvent(siteId: s.id, type: .stageChange, title: "Site Created", description: "New site '\(s.name)' was created")
    }
    
    func updateSite(_ site: ConstructionSite) {
        if let idx = sites.firstIndex(where: { $0.id == site.id }) {
            sites[idx] = site
            saveSites()
        }
    }
    
    func deleteSite(_ site: ConstructionSite) {
        sites.removeAll { $0.id == site.id }
        reports.removeAll { $0.siteId == site.id }
        issues.removeAll { $0.siteId == site.id }
        tasks.removeAll { $0.siteId == site.id }
        photos.removeAll { $0.siteId == site.id }
        materials.removeAll { $0.siteId == site.id }
        deliveries.removeAll { $0.siteId == site.id }
        documents.removeAll { $0.siteId == site.id }
        timeline.removeAll { $0.siteId == site.id }
        saveSites()
        saveReports(); saveIssues(); saveTasks(); savePhotos(); saveMaterials(); saveDeliveries(); saveDocuments(); saveTimeline()
    }
    
    func updateStageStatus(siteId: UUID, stageId: UUID, status: WorkStage.StageStatus) {
        guard let sIdx = sites.firstIndex(where: { $0.id == siteId }) else { return }
        if let stIdx = sites[sIdx].stages.firstIndex(where: { $0.id == stageId }) {
            let stageName = sites[sIdx].stages[stIdx].name
            sites[sIdx].stages[stIdx].status = status
            recalcProgress(siteIdx: sIdx)
            saveSites()
            addTimelineEvent(siteId: siteId, type: .stageChange, title: "Stage Updated", description: "\(stageName) → \(status.rawValue)")
        }
    }
    
    private func recalcProgress(siteIdx: Int) {
        let stages = sites[siteIdx].stages
        let done = stages.filter { $0.status == .done }.count
        sites[siteIdx].progressPercent = stages.isEmpty ? 0 : Double(done) / Double(stages.count) * 100
    }
    
    // MARK: - Reports
    func addReport(_ report: DailyReport) {
        reports.insert(report, at: 0)
        saveReports()
        addTimelineEvent(siteId: report.siteId, type: .report, title: "Daily Report", description: report.workCompleted)
    }
    
    func deleteReport(_ report: DailyReport) {
        reports.removeAll { $0.id == report.id }
        saveReports()
    }
    
    func reports(for siteId: UUID) -> [DailyReport] {
        reports.filter { $0.siteId == siteId }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Issues
    func addIssue(_ issue: Issue) {
        issues.insert(issue, at: 0)
        saveIssues()
        addTimelineEvent(siteId: issue.siteId, type: .issue, title: "Issue: \(issue.title)", description: issue.description)
    }
    
    func updateIssue(_ issue: Issue) {
        if let idx = issues.firstIndex(where: { $0.id == issue.id }) {
            issues[idx] = issue
            saveIssues()
        }
    }
    
    func deleteIssue(_ issue: Issue) {
        issues.removeAll { $0.id == issue.id }
        saveIssues()
    }
    
    func issues(for siteId: UUID) -> [Issue] {
        issues.filter { $0.siteId == siteId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Tasks
    func addTask(_ task: SiteTask) {
        tasks.insert(task, at: 0)
        saveTasks()
        addTimelineEvent(siteId: task.siteId, type: .task, title: "Task: \(task.title)", description: "Assigned to \(task.assignedWorker)")
    }
    
    func updateTask(_ task: SiteTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
            saveTasks()
        }
    }
    
    func deleteTask(_ task: SiteTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func tasks(for siteId: UUID) -> [SiteTask] {
        tasks.filter { $0.siteId == siteId }.sorted { $0.dueDate < $1.dueDate }
    }
    
    func todayTasks() -> [SiteTask] {
        let calendar = Calendar.current
        return tasks.filter { calendar.isDateInToday($0.dueDate) || $0.status == .overdue }
    }
    
    // MARK: - Photos
    func addPhoto(_ photo: SitePhoto) {
        photos.insert(photo, at: 0)
        savePhotos()
        addTimelineEvent(siteId: photo.siteId, type: .photo, title: "Photo Added", description: "\(photo.type.rawValue) - \(photo.zone)")
    }
    
    func deletePhoto(_ photo: SitePhoto) {
        photos.removeAll { $0.id == photo.id }
        savePhotos()
    }
    
    func photos(for siteId: UUID) -> [SitePhoto] {
        photos.filter { $0.siteId == siteId }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Materials
    func addMaterialRequest(_ req: MaterialRequest) {
        materials.insert(req, at: 0)
        saveMaterials()
    }
    
    func updateMaterialRequest(_ req: MaterialRequest) {
        if let idx = materials.firstIndex(where: { $0.id == req.id }) {
            materials[idx] = req
            saveMaterials()
        }
    }
    
    func deleteMaterialRequest(_ req: MaterialRequest) {
        materials.removeAll { $0.id == req.id }
        saveMaterials()
    }
    
    func materials(for siteId: UUID) -> [MaterialRequest] {
        materials.filter { $0.siteId == siteId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Deliveries
    func addDelivery(_ delivery: Delivery) {
        deliveries.insert(delivery, at: 0)
        saveDeliveries()
        addTimelineEvent(siteId: delivery.siteId, type: .delivery, title: "Delivery from \(delivery.supplier)", description: delivery.items)
    }
    
    func deleteDelivery(_ delivery: Delivery) {
        deliveries.removeAll { $0.id == delivery.id }
        saveDeliveries()
    }
    
    func deliveries(for siteId: UUID) -> [Delivery] {
        deliveries.filter { $0.siteId == siteId }.sorted { $0.deliveryDate > $1.deliveryDate }
    }
    
    // MARK: - Documents
    func addDocument(_ doc: SiteDocument) {
        documents.insert(doc, at: 0)
        saveDocuments()
    }
    
    func deleteDocument(_ doc: SiteDocument) {
        documents.removeAll { $0.id == doc.id }
        saveDocuments()
    }
    
    func documents(for siteId: UUID) -> [SiteDocument] {
        documents.filter { $0.siteId == siteId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Timeline
    func addTimelineEvent(siteId: UUID, type: TimelineEvent.EventType, title: String, description: String) {
        let event = TimelineEvent(siteId: siteId, date: Date(), type: type, title: title, description: description)
        timeline.insert(event, at: 0)
        saveTimeline()
    }
    
    func timeline(for siteId: UUID) -> [TimelineEvent] {
        timeline.filter { $0.siteId == siteId }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Analytics
    var activeSitesCount: Int { sites.filter { $0.status == .active }.count }
    var openIssuesCount: Int { issues.filter { $0.status != .resolved }.count }
    var criticalIssuesCount: Int { issues.filter { $0.severity == .critical && $0.status != .resolved }.count }
    var pendingTasksCount: Int { tasks.filter { $0.status != .done }.count }
    
    func openIssues(for siteId: UUID) -> Int {
        issues.filter { $0.siteId == siteId && $0.status != .resolved }.count
    }
    
    // MARK: - Persistence
    private func loadAll() {
        sites = load([ConstructionSite].self, key: sitesKey) ?? []
        reports = load([DailyReport].self, key: reportsKey) ?? []
        issues = load([Issue].self, key: issuesKey) ?? []
        tasks = load([SiteTask].self, key: tasksKey) ?? []
        photos = load([SitePhoto].self, key: photosKey) ?? []
        materials = load([MaterialRequest].self, key: materialsKey) ?? []
        deliveries = load([Delivery].self, key: deliveriesKey) ?? []
        documents = load([SiteDocument].self, key: documentsKey) ?? []
        timeline = load([TimelineEvent].self, key: timelineKey) ?? []
    }
    
    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func saveSites() { save(sites, key: sitesKey) }
    private func saveReports() { save(reports, key: reportsKey) }
    private func saveIssues() { save(issues, key: issuesKey) }
    private func saveTasks() { save(tasks, key: tasksKey) }
    private func savePhotos() { save(photos, key: photosKey) }
    private func saveMaterials() { save(materials, key: materialsKey) }
    private func saveDeliveries() { save(deliveries, key: deliveriesKey) }
    private func saveDocuments() { save(documents, key: documentsKey) }
    private func saveTimeline() { save(timeline, key: timelineKey) }
    
    // MARK: - Demo Data
    private func seedDemoData() {
        let siteId1 = UUID()
        let siteId2 = UUID()
        
        var stages1 = WorkStage.defaultStages()
        stages1[0].status = .done
        stages1[1].status = .done
        stages1[2].status = .inProgress
        
        var stages2 = WorkStage.defaultStages()
        stages2[0].status = .done
        
        let site1 = ConstructionSite(
            id: siteId1, name: "Maple Street Residence", address: "142 Maple Street, Portland, OR",
            clientName: "Robert Dawson", startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            plannedEndDate: Calendar.current.date(byAdding: .month, value: 4, to: Date())!,
            siteType: .house, status: .active, notes: "Two-story residential build",
            stages: stages1, zones: SiteZone.defaultZones.prefix(5).enumerated().map { i, name in
                SiteZone(name: name, status: i < 2 ? .done : .notStarted, notes: "")
            },
            responsiblePerson: "Alex Johnson", progressPercent: 37.5
        )
        
        let site2 = ConstructionSite(
            id: siteId2, name: "Downtown Office Renovation", address: "88 Commerce Blvd, Suite 3, Portland",
            clientName: "TechCorp Inc.", startDate: Calendar.current.date(byAdding: .weekOfMonth, value: -1, to: Date())!,
            plannedEndDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())!,
            siteType: .office, status: .active, notes: "Full floor office renovation",
            stages: stages2, zones: SiteZone.defaultZones.suffix(3).enumerated().map { i, name in
                SiteZone(name: name, status: .notStarted, notes: "")
            },
            responsiblePerson: "Alex Johnson", progressPercent: 12.5
        )
        
        sites = [site1, site2]
        
        issues = [
            Issue(id: UUID(), siteId: siteId1, title: "Crack in foundation wall", category: .structural, severity: .high, zone: "Basement", description: "Horizontal crack approximately 2m long on the north wall", assignedWorker: "Mike Chen", deadline: Calendar.current.date(byAdding: .day, value: 3, to: Date()), status: .open, createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
            Issue(id: UUID(), siteId: siteId1, title: "Electrical conduit misaligned", category: .electrical, severity: .medium, zone: "Kitchen", description: "Conduit not following approved plan — needs rerouting", assignedWorker: "Sam Park", deadline: Calendar.current.date(byAdding: .day, value: 5, to: Date()), status: .inReview, createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
            Issue(id: UUID(), siteId: siteId2, title: "Water leak near entrance", category: .plumbing, severity: .critical, zone: "Corridor", description: "Active leak from overhead pipe, causing floor damage", assignedWorker: "Jake Torres", deadline: Calendar.current.date(byAdding: .day, value: 1, to: Date()), status: .fixing, createdAt: Date())
        ]
        
        tasks = [
            SiteTask(id: UUID(), siteId: siteId1, title: "Install kitchen rough plumbing", zone: "Kitchen", stage: "Plumbing", assignedWorker: "Jake Torres", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, status: .inProgress, createdAt: Date()),
            SiteTask(id: UUID(), siteId: siteId1, title: "Frame bedroom walls", zone: "Bedroom", stage: "Walls", assignedWorker: "Mike Chen", dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, status: .overdue, createdAt: Date()),
            SiteTask(id: UUID(), siteId: siteId2, title: "Remove old ceiling tiles", zone: "Corridor", stage: "Demolition", assignedWorker: "Sam Park", dueDate: Date(), status: .todo, createdAt: Date())
        ]
        
        materials = [
            MaterialRequest(id: UUID(), siteId: siteId1, materialName: "PVC Pipe 2\"", quantity: 50, unit: "m", urgency: .high, zone: "Kitchen", requestedBy: "Jake Torres", neededDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, status: .approved, createdAt: Date()),
            MaterialRequest(id: UUID(), siteId: siteId1, materialName: "Drywall Sheets", quantity: 40, unit: "pcs", urgency: .normal, zone: "Bedroom", requestedBy: "Mike Chen", neededDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!, status: .requested, createdAt: Date())
        ]
        
        let report = DailyReport(id: UUID(), siteId: siteId1, siteName: "Maple Street Residence", date: Date(), weather: .sunny, workersPresent: 6, workCompleted: "Completed bathroom rough plumbing. Began kitchen conduit installation.", problems: "Minor delay on pipe delivery.", materialsDelivered: "50 pcs drywall", notes: "Good progress overall.", photoCount: 4, issueCount: 1)
        reports = [report]
        
        let event1 = TimelineEvent(siteId: siteId1, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, type: .issue, title: "Issue Reported", description: "Crack in foundation wall identified")
        let event2 = TimelineEvent(siteId: siteId1, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, type: .report, title: "Daily Report", description: "6 workers on site, plumbing progress")
        let event3 = TimelineEvent(siteId: siteId1, date: Date(), type: .stageChange, title: "Stage Updated", description: "Plumbing → In Progress")
        timeline = [event3, event2, event1]
        
        saveSites(); saveReports(); saveIssues(); saveTasks(); savePhotos(); saveMaterials(); saveDeliveries(); saveDocuments(); saveTimeline()
    }
}
