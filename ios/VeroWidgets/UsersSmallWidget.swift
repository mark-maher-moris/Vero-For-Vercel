import WidgetKit
import SwiftUI

// MARK: - Data

struct UsersEntry: TimelineEntry {
    let date: Date
    let projectName: String
    let total24h: Int
    let lastHour: Int
    let bounceRate: Int
    let timeseries: [(date: String, value: Int)]
    let isSubscribed: Bool
    let isDemoMode: Bool
    let lastUpdated: Date?
    let isConfigured: Bool
}

// MARK: - Provider

struct UsersProvider: TimelineProvider {
    func placeholder(in context: Context) -> UsersEntry {
        UsersEntry(date: .now, projectName: "my-project", total24h: 1240,
                   lastHour: 18, bounceRate: 42, timeseries: demoTimeseries(),
                   isSubscribed: true, isDemoMode: false,
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
        let timeseriesJson = d.veroString("vero_users_timeseries")
        let rawTimeseries = parseJSONArray(timeseriesJson)
        let timeseries: [(date: String, value: Int)] = rawTimeseries.compactMap { entry in
            guard let date = entry["date"] as? String,
                  let value = entry["value"] as? Int else { return nil }
            return (date: date, value: value)
        }
        return UsersEntry(
            date: .now,
            projectName: d.veroString("vero_users_project_name", default: "No project"),
            total24h: d.veroInt("vero_users_total_24h"),
            lastHour: d.veroInt("vero_users_last_hour"),
            bounceRate: d.veroInt("vero_users_bounce_rate"),
            timeseries: timeseries,
            isSubscribed: d.veroBool("vero_is_subscribed"),
            isDemoMode: d.veroBool("vero_is_demo_mode"),
            lastUpdated: ISO8601DateFormatter().date(from: d.veroString("vero_last_updated")),
            isConfigured: !projectId.isEmpty
        )
    }
}

// MARK: - View

struct UsersSmallView: View {
    let entry: UsersEntry

    var body: some View {
        VStack(spacing: 2) {
            Text(entry.projectName)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .center)

            // Numbers at top
            HStack(spacing: 4) {
                Text("24h")
                    .font(.system(size: 7))
                    .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                Text(formatNumber(entry.total24h))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            // Simple chart
            if entry.timeseries.isEmpty {
                Spacer()
                Text("No data")
                    .font(.system(size: 8))
                    .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                Spacer()
            } else {
                SimpleLineChart(data: entry.timeseries.map { $0.value })
            }

            Text(relativeTime(from: entry.lastUpdated))
                .font(.system(size: 7))
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
        }
        .padding(5)
        .overlay {
            if !entry.isConfigured {
                ZStack {
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
            }
        }
        .widgetURL(makeWidgetURL(for: "users"))
        .applyWidgetBackground(Color.veroSurface)
    }
}

// MARK: - Simple Line Chart

struct SimpleLineChart: View {
    let data: [Int]

    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1
            let minValue = 0
            let range = maxValue - minValue

            ZStack {
                // Fill under the line
                Path { path in
                    guard !data.isEmpty else { return }
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let step = width / CGFloat(max(data.count - 1, 1))

                    path.move(to: CGPoint(x: 0, y: height))

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * step
                        let normalizedValue = range > 0 ? CGFloat(value - minValue) / CGFloat(range) : 0
                        let y = height - (normalizedValue * height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    path.addLine(to: CGPoint(x: geometry.size.width, y: height))
                    path.closeSubpath()
                }
                .fill(Color.veroSuccess.opacity(0.2))

                // Line
                Path { path in
                    guard !data.isEmpty else { return }
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let step = width / CGFloat(max(data.count - 1, 1))

                    if let firstValue = data.first {
                        let normalizedValue = range > 0 ? CGFloat(firstValue - minValue) / CGFloat(range) : 0
                        let y = height - (normalizedValue * height)
                        path.move(to: CGPoint(x: 0, y: y))
                    }

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * step
                        let normalizedValue = range > 0 ? CGFloat(value - minValue) / CGFloat(range) : 0
                        let y = height - (normalizedValue * height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.veroSuccess, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
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

// MARK: - Demo data helper

private func demoTimeseries() -> [(date: String, value: Int)] {
    let values = [120, 145, 132, 180, 165, 210, 195, 240, 225, 280, 265, 310]
    return values.enumerated().map { index, value in
        (date: "\(index)h", value: value)
    }
}
