import SwiftUI
import Combine

class ApplicationMainState: ObservableObject {
    @AppStorage("appTheme") var appTheme: String = "system" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("measurementUnit") var measurementUnit: String = "metric"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("overdueTaskAlerts") var overdueTaskAlerts: Bool = true
    @AppStorage("criticalIssueAlerts") var criticalIssueAlerts: Bool = true
    @AppStorage("materialDelayAlerts") var materialDelayAlerts: Bool = false
    @AppStorage("workerMissingAlerts") var workerMissingAlerts: Bool = false
    @AppStorage("reportReminderAlerts") var reportReminderAlerts: Bool = true
    
    var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

// MARK: - Design System Colors
struct UFColors {
    static let primary = Color(hex: "#FF6B35")
    static let primaryDark = Color(hex: "#E85A25")
    static let secondary = Color(hex: "#1A1A2E")
    static let accent = Color(hex: "#FFD166")
    static let success = Color(hex: "#06D6A0")
    static let warning = Color(hex: "#FFD166")
    static let danger = Color(hex: "#EF476F")
    static let info = Color(hex: "#118AB2")
    
    static let surface = Color(hex: "#F8F7F4")
    static let surfaceDark = Color(hex: "#1E1E2E")
    static let cardLight = Color.white
    static let cardDark = Color(hex: "#2A2A3E")
    
    static let textPrimary = Color(hex: "#1A1A2E")
    static let textSecondary = Color(hex: "#6B7280")
    static let textTertiary = Color(hex: "#9CA3AF")
    
    static let gradientOrange = LinearGradient(
        colors: [Color(hex: "#FF6B35"), Color(hex: "#FF8C42")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientDark = LinearGradient(
        colors: [Color(hex: "#1A1A2E"), Color(hex: "#2D2D44")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientSuccess = LinearGradient(
        colors: [Color(hex: "#06D6A0"), Color(hex: "#04A47C")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientDanger = LinearGradient(
        colors: [Color(hex: "#EF476F"), Color(hex: "#D43560")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Typography
struct UFFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    static func headline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    static func caption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}
