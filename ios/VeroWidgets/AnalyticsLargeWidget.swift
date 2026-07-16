import WidgetKit
import SwiftUI

// MARK: - Data

struct AnalyticsSource {
    let source: String
    let visitors: Int
}

struct AnalyticsWidgetEntry: TimelineEntry {
    let date: Date
    let projectName: String
    let visitors24h: Int
    let bounceRate: Int
    let sources: [AnalyticsSource]
    let timeseries30Day: [(date: String, value: Int)]
    let isSubscribed: Bool
    let isDemoMode: Bool
    let analyticsEnabled: Bool
    let isConfigured: Bool
    let lastUpdated: Date?
}

// MARK: - Provider

struct AnalyticsLargeProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnalyticsWidgetEntry {
        AnalyticsWidgetEntry(date: .now, projectName: "my-project",
                             visitors24h: 2_840, bounceRate: 38,
                             sources: demoSources(), timeseries30Day: demo30DayTimeseries(),
                             isSubscribed: true, isDemoMode: false,
                             analyticsEnabled: true, isConfigured: true, lastUpdated: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (AnalyticsWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AnalyticsWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> AnalyticsWidgetEntry {
        let d = UserDefaults.vero
        let projectId = d.veroString("vero_project_analytics_id")
        let sourcesJson = d.veroString("vero_analytics_sources")
        let rawSources = parseJSONArray(sourcesJson)
        let sources: [AnalyticsSource] = rawSources.prefix(5).map { src in
            AnalyticsSource(
                source: (src["source"] as? String ?? "Direct"),
                visitors: src["visitors"] as? Int ?? 0
            )
        }
        let timeseriesJson = d.veroString("vero_analytics_30day_timeseries")
        let rawTimeseries = parseJSONArray(timeseriesJson)
        let timeseries30Day: [(date: String, value: Int)] = rawTimeseries.compactMap { entry in
            guard let date = entry["date"] as? String,
                  let value = entry["value"] as? Int else { return nil }
            return (date: date, value: value)
        }
        return AnalyticsWidgetEntry(
            date: .now,
            projectName: d.veroString("vero_analytics_project_name", default: "Select Project"),
            visitors24h: d.veroInt("vero_analytics_visitors_24h"),
            bounceRate: d.veroInt("vero_analytics_bounce_rate"),
            sources: sources,
            timeseries30Day: timeseries30Day,
            isSubscribed: d.veroBool("vero_is_subscribed"),
            isDemoMode: d.veroBool("vero_is_demo_mode"),
            analyticsEnabled: d.veroBool("vero_analytics_enabled", default: true),
            isConfigured: !projectId.isEmpty,
            lastUpdated: ISO8601DateFormatter().date(from: d.veroString("vero_last_updated"))
        )
    }
}

// MARK: - View

struct AnalyticsLargeView: View {
    let entry: AnalyticsWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("ANALYTICS")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.veroPrimary)
                Text("·")
                    .foregroundColor(.veroSubtle)
                    .font(.system(size: 8))
                Text(entry.projectName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .padding(.bottom, 8)

            // Stats row
            HStack(spacing: 8) {
                statCard(title: "24H VISITORS", value: formatNumber(entry.visitors24h),
                         color: .veroPrimary)
                statCard(title: "BOUNCE RATE", value: "\(entry.bounceRate)%",
                         color: .veroWarning)
            }
            .padding(.bottom, 10)

            // Content
            if !entry.analyticsEnabled {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 20))
                        .foregroundColor(.veroSubtle)
                    Text("Enable Vercel Analytics\nto use this widget")
                        .font(.system(size: 10))
                        .foregroundColor(.veroSubtle)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else if !entry.isConfigured {
                Spacer()
                Text("Tap to configure widget")
                    .font(.system(size: 10))
                    .foregroundColor(.veroSubtle)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("TRAFFIC SOURCES")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                        .padding(.bottom, 6)

                    ForEach(Array(entry.sources.enumerated()), id: \.offset) { _, src in
                        HStack {
                            Text(src.source)
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(formatNumber(src.visitors))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.veroPrimary)
                        }
                        .padding(.vertical, 3)
                        if src.source != entry.sources.last?.source {
                            Divider().background(Color.veroSubtle.opacity(0.3))
                        }
                    }

                    Text("30-DAY VISITORS")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                        .padding(.top, 8)
                        .padding(.bottom, 6)

                    if entry.timeseries30Day.isEmpty {
                        Text("No data")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                    } else {
                        SimpleLineChart(data: entry.timeseries30Day.map { $0.value })
                            .frame(height: 60)
                    }
                }
                Spacer(minLength: 0)
            }

            // Footer
            Text(relativeTime(from: entry.lastUpdated))
                .font(.system(size: 7))
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 6)
        }
        .padding(12)
        .widgetURL(makeWidgetURL(for: "analytics"))
        .applyWidgetBackground(Color.veroSurface)
    }

    @ViewBuilder
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.veroSurfaceVariant)
        .cornerRadius(4)
    }
}

// MARK: - Widget definition

struct AnalyticsLargeWidget: Widget {
    let kind = "AnalyticsLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnalyticsLargeProvider()) { entry in
            AnalyticsLargeView(entry: entry)
        }
        .configurationDisplayName("Vero Analytics")
        .description("Traffic, visitors, bounce rate and top traffic sources. Requires Vercel Analytics.")
        .supportedFamilies([.systemLarge])
    }
}

private func demoSources() -> [AnalyticsSource] {
    [
        AnalyticsSource(source: "Direct", visitors: 1_200),
        AnalyticsSource(source: "google.com", visitors: 840),
        AnalyticsSource(source: "twitter.com", visitors: 420),
        AnalyticsSource(source: "github.com", visitors: 210),
        AnalyticsSource(source: "ycombinator.com", visitors: 110),
    ]
}

private func demo30DayTimeseries() -> [(date: String, value: Int)] {
    let values = [850, 920, 780, 1050, 980, 1200, 1150, 1380, 1250, 1420, 1350, 1580, 1480, 1720, 1650, 1890, 1800, 2050, 1950, 2180, 2100, 2350, 2250, 2480, 2400, 2650, 2550, 2800, 2700, 2950]
    return values.enumerated().map { index, value in
        (date: "Day \(index + 1)", value: value)
    }
}
