import Foundation
import SwiftUI

// MARK: - App Group & UserDefaults helpers

let kAppGroupID = "group.com.buildagon.vero"

extension UserDefaults {
    static var vero: UserDefaults {
        UserDefaults(suiteName: kAppGroupID) ?? .standard
    }

    func veroString(_ key: String, default d: String = "") -> String {
        string(forKey: "flutter.\(key)") ?? d
    }
    func veroBool(_ key: String, default d: Bool = false) -> Bool {
        // home_widget stores bools as 1.0/0.0 doubles or plain Bool
        if let b = object(forKey: "flutter.\(key)") as? Bool { return b }
        if let n = object(forKey: "flutter.\(key)") as? NSNumber { return n.boolValue }
        return d
    }
    func veroInt(_ key: String, default d: Int = 0) -> Int {
        if let n = object(forKey: "flutter.\(key)") as? NSNumber { return n.intValue }
        return d
    }
}

// MARK: - Shared data model

struct VeroWidgetData {
    let isSubscribed: Bool
    let lastUpdated: Date?

    static func load() -> VeroWidgetData {
        let defaults = UserDefaults.vero
        let isSubscribed = defaults.veroBool("vero_is_subscribed")
        let lastUpdatedStr = defaults.veroString("vero_last_updated")
        let lastUpdated = ISO8601DateFormatter().date(from: lastUpdatedStr)
        return VeroWidgetData(isSubscribed: isSubscribed, lastUpdated: lastUpdated)
    }
}

// MARK: - JSON parsing

func parseJSONArray(_ json: String) -> [[String: Any]] {
    guard !json.isEmpty,
          let data = json.data(using: .utf8),
          let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }
    return array
}

// MARK: - Formatting helpers

func formatNumber(_ n: Int) -> String {
    switch n {
    case 1_000_000...: return "\(n / 1_000_000)M"
    case 1_000...: return "\(n / 1_000)K"
    default: return "\(n)"
    }
}

func relativeTime(from date: Date?) -> String {
    guard let date = date else { return "—" }
    let diff = Date().timeIntervalSince(date)
    switch diff {
    case ..<60: return "Just now"
    case ..<3600: return "\(Int(diff / 60))m ago"
    case ..<86400: return "\(Int(diff / 3600))h ago"
    default: return "\(Int(diff / 86400))d ago"
    }
}

func formatTimestamp(_ ms: Int) -> String {
    guard ms > 0 else { return "" }
    let date = Date(timeIntervalSince1970: Double(ms) / 1000.0)
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss"
    return f.string(from: date)
}

// MARK: - App theme colours (matching Flutter's AppTheme)

extension Color {
    static let veroPrimary = Color(hex: "#4A9EFF")
    static let veroSurface = Color(hex: "#0D0D0D")
    static let veroSurfaceVariant = Color(hex: "#1A1A1A")
    static let veroOnSurface = Color.white
    static let veroOnSurfaceVariant = Color(hex: "#B0B0B0")
    static let veroSuccess = Color(hex: "#50E3C2")
    static let veroWarning = Color(hex: "#F5A623")
    static let veroError = Color(hex: "#FF4F4F")
    static let veroSubtle = Color(hex: "#444444")
    static let veroMuted = Color(hex: "#888888")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Lock overlay view

struct WidgetLockView: View {
    var message: String = "Upgrade to Pro"
    var subMessage: String = "Open Vero to unlock"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
            VStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Text(subMessage)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(12)
        }
    }
}

// MARK: - Status badge colour

func statusColor(_ state: String) -> Color {
    switch state.uppercased() {
    case "READY": return .veroSuccess
    case "ERROR", "CANCELED": return .veroError
    case "BUILDING", "INITIALIZING", "QUEUED": return .veroWarning
    default: return .veroMuted
    }
}

// MARK: - Widget URL scheme for taps (opens app with context)

func widgetURL(for type: String) -> URL {
    URL(string: "vero://widget/configure?type=\(type)") ?? URL(string: "vero://")!
}
