import Foundation
import SwiftUI
import UserNotifications

class WorkersViewModel: ObservableObject {
    @Published var workers: [Worker] = []
    @Published var attendance: [AttendanceRecord] = []
    
    private let workersKey = "unitflow_workers"
    private let attendanceKey = "unitflow_attendance"
    
    init() {
        load()
        if workers.isEmpty { seedDemo() }
    }
    
    func addWorker(_ worker: Worker) {
        workers.append(worker)
        save()
    }
    
    func updateWorker(_ worker: Worker) {
        if let idx = workers.firstIndex(where: { $0.id == worker.id }) {
            workers[idx] = worker
            save()
        }
    }
    
    func deleteWorker(_ worker: Worker) {
        workers.removeAll { $0.id == worker.id }
        save()
    }
    
    func checkIn(worker: Worker, siteId: UUID, notes: String = "") {
        let record = AttendanceRecord(workerId: worker.id, workerName: worker.name, siteId: siteId, date: Date(), startTime: Date(), endTime: nil, notes: notes)
        attendance.append(record)
        saveAttendance()
    }
    
    func checkOut(workerId: UUID) {
        if let idx = attendance.lastIndex(where: { $0.workerId == workerId && $0.endTime == nil }) {
            attendance[idx].endTime = Date()
            saveAttendance()
        }
    }
    
    func todayAttendance(siteId: UUID) -> [AttendanceRecord] {
        let calendar = Calendar.current
        return attendance.filter { calendar.isDateInToday($0.date) && $0.siteId == siteId }
    }
    
    func onSiteCount() -> Int {
        workers.filter { $0.status == .onSite }.count
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: workersKey),
           let w = try? JSONDecoder().decode([Worker].self, from: data) { workers = w }
        if let data = UserDefaults.standard.data(forKey: attendanceKey),
           let a = try? JSONDecoder().decode([AttendanceRecord].self, from: data) { attendance = a }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(workers) {
            UserDefaults.standard.set(data, forKey: workersKey)
        }
    }
    
    private func saveAttendance() {
        if let data = try? JSONEncoder().encode(attendance) {
            UserDefaults.standard.set(data, forKey: attendanceKey)
        }
    }
    
    private func seedDemo() {
        workers = [
            Worker(name: "Mike Chen", role: "Carpenter", phone: "+1 503-555-0121", activeSite: "Maple Street Residence", status: .onSite, notes: "Lead framer"),
            Worker(name: "Jake Torres", role: "Plumber", phone: "+1 503-555-0184", activeSite: "Maple Street Residence", status: .onSite, notes: "Licensed plumber"),
            Worker(name: "Sam Park", role: "Electrician", phone: "+1 503-555-0267", activeSite: "Downtown Office Renovation", status: .onSite, notes: "Master electrician"),
            Worker(name: "Lisa Evans", role: "Laborer", phone: "+1 503-555-0398", activeSite: "Maple Street Residence", status: .offSite, notes: ""),
            Worker(name: "Tom Bradley", role: "Mason", phone: "+1 503-555-0445", activeSite: "", status: .sick, notes: "Back next Monday")
        ]
        save()
    }
}

// MARK: - NotificationsViewModel
class NotificationsViewModel: ObservableObject {
    @Published var permissionGranted: Bool = false
    
    init() {
        checkPermission()
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.permissionGranted = granted
                completion(granted)
            }
        }
    }
    
    func scheduleOverdueTaskNotification(taskTitle: String, dueDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Overdue Task"
        content.body = "\(taskTitle) is past due date"
        content.sound = .default
        content.categoryIdentifier = "OVERDUE_TASK"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, dueDate.timeIntervalSinceNow), repeats: false)
        let request = UNNotificationRequest(identifier: "task_\(taskTitle)_\(dueDate.timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleCriticalIssueNotification(issueTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 Critical Issue"
        content.body = "\(issueTitle) requires immediate attention"
        content.sound = .defaultCritical
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "issue_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleReportReminder() {
        let content = UNMutableNotificationContent()
        content.title = "📋 Daily Report Reminder"
        content.body = "Don't forget to submit today's site report"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 17
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_report_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelReportReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_report_reminder"])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
