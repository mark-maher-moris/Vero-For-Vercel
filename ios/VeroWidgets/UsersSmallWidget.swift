import WidgetKit
import SwiftUI

// MARK: - Data

struct UsersEntry: TimelineEntry {
    let date: Date
    let projectName: String
    let total24h: Int
    let lastHour: Int
    let bounceRate: Int
    let isSubscribed: Bool
    let lastUpdated: Date?
    let isConfigured: Bool
}

// MARK: - Provider

struct UsersProvider: TimelineProvider {
    func placeholder(in context: Context) -> UsersEntry {
        UsersEntry(date: .now, projectName: "my-project", total24h: 1240,
                   lastHour: 18, bounceRate: 42, isSubscribed: true,
                   lastUpdated: .now, isConfigured: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (UsersEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsersEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> UsersEntry {
        let d = UserDefaults.vero
        let projectId = d.veroString("vero_project_users_id")
        return UsersEntry(
            date: .now,
            projectName: d.veroString("vero_users_project_name", default: "No project"),
            total24h: d.veroInt("vero_users_total_24h"),
            lastHour: d.veroInt("vero_users_last_hour"),
            bounceRate: d.veroInt("vero_users_bounce_rate"),
            isSubscribed: d.veroBool("vero_is_subscribed"),
            lastUpdated: ISO8601DateFormatter().date(from: d.veroString("vero_last_updated")),
            isConfigured: !projectId.isEmpty
        )
    }
}

// MARK: - View

struct UsersSmallView: View {
    let entry: UsersEntry

    var body: some View {
        ZStack {
            Color.veroSurface.ignoresSafeArea()

            VStack(spacing: 2) {
                Text(entry.projectName)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.veroMuted)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 4)

                Text("24h")
                    .font(.system(size: 7))
                    .foregroundColor(.veroSubtle)

                Text(formatNumber(entry.total24h))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 2) {
                    Circle()
                        .fill(Color.veroSuccess)
                        .frame(width: 5, height: 5)
                    Text(formatNumber(entry.lastHour))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.veroSuccess)
                }

                Text("online")
                    .font(.system(size: 7))
                    .foregroundColor(.veroSubtle)

                Spacer(minLength: 4)

                Text("\(entry.bounceRate)% bounce")
                    .font(.system(size: 8))
                    .foregroundColor(.veroSubtle)

                Text(relativeTime(from: entry.lastUpdated))
                    .font(.system(size: 7))
                    .foregroundColor(Color(hex: "#333333"))
            }
            .padding(10)

            if !entry.isConfigured {
                Color.black.opacity(0.7)
                VStack(spacing: 4) {
                    Image(systemName: "gear")
                        .foregroundColor(.veroMuted)
                        .font(.system(size: 16))
                    Text("Tap to configure")
                        .font(.system(size: 9))
                        .foregroundColor(.veroMuted)
                        .multilineTextAlignment(.center)
                }
            }

            if !entry.isSubscribed {
                WidgetLockView(message: "Pro Required", subMessage: "Open Vero")
            }
        }
        .widgetURL(widgetURL(for: "users"))
    }
}

// MARK: - Widget definition

struct UsersSmallWidget: Widget {
    let kind = "UsersSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UsersProvider()) { entry in
            UsersSmallView(entry: entry)
        }
        .configurationDisplayName("Vero Users")
        .description("Track real-time visitors and bounce rate for your project.")
        .supportedFamilies([.systemSmall])
    }
}
