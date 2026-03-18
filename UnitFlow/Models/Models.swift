import Foundation
import SwiftUI

// MARK: - User Model
struct User: Codable, Identifiable {
    var id: UUID = UUID()
    var fullName: String
    var companyName: String
    var email: String
    var role: UserRole
    
    enum UserRole: String, Codable, CaseIterable {
        case foreman = "Foreman"
        case builder = "Builder"
        case siteManager = "Site Manager"
        case inspector = "Inspector"
    }
}

// MARK: - Site Model
struct ConstructionSite: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var address: String
    var clientName: String
    var startDate: Date
    var plannedEndDate: Date
    var siteType: SiteType
    var status: SiteStatus
    var notes: String
    var stages: [WorkStage]
    var zones: [SiteZone]
    var responsiblePerson: String
    var progressPercent: Double
    var photoData: Data?
    
    enum SiteType: String, Codable, CaseIterable {
        case house = "House"
        case apartment = "Apartment"
        case commercial = "Commercial"
        case office = "Office"
        case outdoor = "Outdoor"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .house: return "house.fill"
            case .apartment: return "building.2.fill"
            case .commercial: return "storefront.fill"
            case .office: return "building.fill"
            case .outdoor: return "tree.fill"
            case .custom: return "square.grid.2x2.fill"
            }
        }
    }
    
    enum SiteStatus: String, Codable, CaseIterable {
        case planning = "Planning"
        case active = "Active"
        case paused = "Paused"
        case completed = "Completed"
        
        var color: Color {
            switch self {
            case .planning: return UFColors.info
            case .active: return UFColors.success
            case .paused: return UFColors.warning
            case .completed: return Color.gray
            }
        }
    }
}

// MARK: - Work Stage
struct WorkStage: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var status: StageStatus
    var order: Int
    var startDate: Date? = nil
    var endDate: Date? = nil
    var progressPercent: Double = 0   // 0–100, used for in-progress bar rendering
    
    enum StageStatus: String, Codable, CaseIterable {
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case waiting = "Waiting"
        case done = "Done"
        case blocked = "Blocked"
        
        var color: Color {
            switch self {
            case .notStarted: return Color.gray
            case .inProgress: return UFColors.primary
            case .waiting: return UFColors.warning
            case .done: return UFColors.success
            case .blocked: return UFColors.danger
            }
        }
        
        var icon: String {
            switch self {
            case .notStarted: return "circle"
            case .inProgress: return "arrow.triangle.2.circlepath"
            case .waiting: return "clock"
            case .done: return "checkmark.circle.fill"
            case .blocked: return "xmark.circle.fill"
            }
        }
    }
    
    static func defaultStages() -> [WorkStage] {
        let names = ["Demolition", "Electrical", "Plumbing", "Walls", "Flooring", "Ceiling", "Finishing", "Exterior"]
        return names.enumerated().map { i, name in
            WorkStage(name: name, status: .notStarted, order: i)
        }
    }
}

// MARK: - Site Zone
struct SiteZone: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var status: WorkStage.StageStatus
    var notes: String
    
    static let defaultZones = ["Kitchen", "Bathroom", "Bedroom", "Corridor", "Roof", "Basement", "Facade", "Living Room"]
}

// MARK: - Daily Report
struct DailyReport: Codable, Identifiable {
    var id: UUID = UUID()
    var siteId: UUID
    var siteName: String
    var date: Date
    var weather: WeatherCondition
    var workersPresent: Int
    var workCompleted: String
    var problems: String
    var materialsDelivered: String
    var notes: String
    var photoCount: Int
    var issueCount: Int
    
    enum WeatherCondition: String, Codable, CaseIterable {
        case sunny = "Sunny"
        case cloudy = "Cloudy"
        case rainy = "Rainy"
        case windy = "Windy"
        case snowy = "Snowy"
        case hot = "Hot"
        
        var icon: String {
            switch self {
            case .sunny: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rainy: return "cloud.rain.fill"
            case .windy: return "wind"
            case .snowy: return "snow"
            case .hot: return "thermometer.sun.fill"
            }
        }
    }
}

// MARK: - Issue
struct Issue: Codable, Identifiable {
    var id: UUID = UUID()
    var siteId: UUID
    var title: String
    var category: IssueCategory
    var severity: Severity
    var zone: String
    var description: String
    var assignedWorker: String
    var deadline: Date?
    var status: IssueStatus
    var createdAt: Date
    var photoData: Data?
    
    enum IssueCategory: String, Codable, CaseIterable {
        case structural = "Structural"
        case electrical = "Electrical"
        case plumbing = "Plumbing"
        case safety = "Safety"
        case material = "Material"
        case schedule = "Schedule"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .structural: return "building.columns"
            case .electrical: return "bolt.fill"
            case .plumbing: return "drop.fill"
            case .safety: return "exclamationmark.triangle.fill"
            case .material: return "cube.fill"
            case .schedule: return "calendar.badge.exclamationmark"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }
    
    enum Severity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return UFColors.success
            case .medium: return UFColors.warning
            case .high: return UFColors.primary
            case .critical: return UFColors.danger
            }
        }
    }
    
    enum IssueStatus: String, Codable, CaseIterable {
        case open = "Open"
        case inReview = "In Review"
        case fixing = "Fixing"
        case resolved = "Resolved"
        
        var color: Color {
            switch self {
            case .open: return UFColors.danger
            case .inReview: return UFColors.info
            case .fixing: return UFColors.warning
            case .resolved: return UFColors.success
            }
        }
    }
}

// MARK: - Task
struct SiteTask: Codable, Identifiable {
    var id: UUID = UUID()
    var siteId: UUID
    var title: String
    var zone: String
    var stage: String
    var assignedWorker: String
    var dueDate: Date
    var status: TaskStatus
    var createdAt: Date
    
    enum TaskStatus: String, Codable, CaseIterable {
        case todo = "To Do"
        case inProgress = "In Progress"
        case done = "Done"
        case overdue = "Overdue"
        
        var color: Color {
            switch self {
            case .todo: return Color.gray
            case .inProgress: return UFColors.primary
            case .done: return UFColors.success
            case .overdue: return UFColors.danger
            }
        }
    }
}

enum DomainEvent {
    case trackingDataChanged(TrackingInfo)
    case navigationDataChanged(NavigationInfo)
    case validationCompleted(Bool)
    case endpointReceived(String)
    case permissionStateChanged(PermissionState)
    case phaseChanged(AppPhase)
    case shouldNavigateToMain
    case shouldNavigateToWeb
    case shouldShowPermissionPrompt
    case shouldHidePermissionPrompt
    case networkStatusChanged(Bool)
}

struct Worker: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var role: String
    var phone: String
    var activeSite: String
    var status: WorkerStatus
    var notes: String
    
    enum WorkerStatus: String, Codable, CaseIterable {
        case onSite = "On Site"
        case offSite = "Off Site"
        case sick = "Sick"
        case vacation = "Vacation"
        
        var color: Color {
            switch self {
            case .onSite: return UFColors.success
            case .offSite: return Color.gray
            case .sick: return UFColors.danger
            case .vacation: return UFColors.info
            }
        }
        
        var icon: String {
            switch self {
            case .onSite: return "checkmark.circle.fill"
            case .offSite: return "minus.circle.fill"
            case .sick: return "cross.circle.fill"
            case .vacation: return "beach.umbrella.fill"
            }
        }
    }
}

enum AppPhase {
    case idle
    case loading
    case validating
    case validated
    case processing
    case ready(String)
    case failed
    case offline
}

struct AttendanceRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var workerId: UUID
    var workerName: String
    var siteId: UUID
    var date: Date
    var startTime: Date
    var endTime: Date?
    var notes: String
}

// MARK: - SitePhoto
struct SitePhoto: Codable, Identifiable {
    var id: UUID = UUID()
    var siteId: UUID
    var imageData: Data
    var zone: String
    var date: Date
    var comment: String
    var type: PhotoType
    
    enum PhotoType: String, Codable, CaseIterable {
        case progress = "Progress"
        case problem = "Problem"
        case delivery = "Delivery"
        case finishedResult = "Finished Result"
        case before = "Before"
        case after = "After"
        
        var icon: String {
            switch self {
            case .progress: return "chart.bar.fill"
            case .problem: return "exclamationmark.triangle.fill"
            case .delivery: return "shippingbox.fill"
            case .finishedResult: return "star.fill"
            case .before: return "arrow.left.circle.fill"
            case .after: return "arrow.right.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .progress: return UFColors.primary
            case .problem: return UFColors.danger
            case .delivery: return UFColors.info
            case .finishedResult: return UFColors.success
            case .before: return UFColors.warning
            case .after: return UFColors.success
            }
        }
    }
}

// MARK: - Material Request
struct MaterialRequest: Codable, Identifiable {
    var id: UUID = UUID()
    var siteId: UUID
    var materialName: String
    var quantity: Double
    var unit: String
    var urgency: Urgency
    var zone: String
    var requestedBy: String
    var neededDate: Date
    var status: RequestStatus
    var createdAt: Date
    
    enum Urgency: String, Codable, CaseIterable {
        case low = "Low"
        case normal = "Normal"
        case high = "High"
        case urgent = "Urgent"
        
        var color: Color {
            switch self {
            case .low: return Color.gray
            case .normal: return UFColors.info
            case .high: return UFColors.warning
            case .urgent: return UFColors.danger
            }
        }
    }
    
    enum RequestStatus: String, Codable, CaseIterable {
        case requested = "Requested"
        case approved = "Approved"
        case ordered = "Ordered"
        case delivered = "Delivered"
        case cancelled = "Cancelled"
        
        var color: Color {
            switch self {
            case .requested: return UFColors.info
            case .approved: return UFColors.success
            case .ordered: return UFColors.warning
            case .delivered: return UFColors.success
            case .cancelled: return Color.gray
            }
        }
    }
}

// MARK: - Delivery
struct Delivery: Codable, Identifiable {
    var id: UUID = UUID()
    var siteId: UUID
    var supplier: String
    var deliveryDate: Date
    var items: String
    var notes: String
    var acceptedBy: String
    var photoData: Data?
}

// MARK: - Document
struct SiteDocument: Codable, Identifiable {
    var id: UUID = UUID()
    var siteId: UUID
    var title: String
    var category: DocumentCategory
    var fileData: Data
    var fileName: String
    var createdAt: Date
    var notes: String
    
    enum DocumentCategory: String, Codable, CaseIterable {
        case estimate = "Estimate"
        case receipt = "Receipt"
        case plan = "Plan"
        case contract = "Contract"
        case technicalNote = "Technical Note"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .estimate: return "doc.text.fill"
            case .receipt: return "receipt.fill"
            case .plan: return "map.fill"
            case .contract: return "doc.badge.gearshape.fill"
            case .technicalNote: return "wrench.and.screwdriver.fill"
            case .other: return "folder.fill"
            }
        }
    }
}

// MARK: - Timeline Event
struct TimelineEvent: Codable, Identifiable {
    var id: UUID = UUID()
    var siteId: UUID
    var date: Date
    var type: EventType
    var title: String
    var description: String
    
    enum EventType: String, Codable {
        case task = "Task"
        case photo = "Photo"
        case issue = "Issue"
        case delivery = "Delivery"
        case report = "Report"
        case stageChange = "Stage Change"
        
        var icon: String {
            switch self {
            case .task: return "checkmark.circle.fill"
            case .photo: return "camera.fill"
            case .issue: return "exclamationmark.triangle.fill"
            case .delivery: return "shippingbox.fill"
            case .report: return "doc.text.fill"
            case .stageChange: return "arrow.right.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .task: return UFColors.success
            case .photo: return UFColors.primary
            case .issue: return UFColors.danger
            case .delivery: return UFColors.info
            case .report: return UFColors.secondary
            case .stageChange: return UFColors.accent
            }
        }
    }
}

struct TrackingInfo {
    let data: [String: String]
    
    var isEmpty: Bool { data.isEmpty }
    var isOrganic: Bool { data["af_status"] == "Organic" }
    
    static var empty: TrackingInfo {
        TrackingInfo(data: [:])
    }
}

struct NavigationInfo {
    let data: [String: String]
    
    var isEmpty: Bool { data.isEmpty }
    
    static var empty: NavigationInfo {
        NavigationInfo(data: [:])
    }
}

struct PermissionState {
    var approved: Bool
    var declined: Bool
    var lastAsked: Date?
    
    var canAsk: Bool {
        guard !approved && !declined else { return false }
        if let date = lastAsked {
            return Date().timeIntervalSince(date) / 86400 >= 3
        }
        return true
    }
    
    static var initial: PermissionState {
        PermissionState(approved: false, declined: false, lastAsked: nil)
    }
}

struct AppConfig {
    var mode: String?
    var firstLaunch: Bool
    
    static var initial: AppConfig {
        AppConfig(mode: nil, firstLaunch: true)
    }
}


