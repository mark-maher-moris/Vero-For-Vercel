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
    let isSubscribed: Bool
    let analyticsEnabled: Bool
    let isConfigured: Bool
    let lastUpdated: Date?
}

// MARK: - Provider

struct AnalyticsLargeProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnalyticsWidgetEntry {
        AnalyticsWidgetEntry(date: .now, projectName: "my-project",
                             visitors24h: 2_840, bounceRate: 38,
                             sources: demoSources(), isSubscribed: true,
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
        return AnalyticsWidgetEntry(
            date: .now,
            projectName: d.veroString("vero_analytics_project_name", default: "Select Project"),
            visitors24h: d.veroInt("vero_analytics_visitors_24h"),
            bounceRate: d.veroInt("vero_analytics_bounce_rate"),
            sources: sources,
            isSubscribed: d.veroBool("vero_is_subscribed"),
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
        ZStack {
            Color.veroSurface.ignoresSafeArea()

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
                            .foregroundColor(.veroSubtle)
                            .padding(.bottom, 6)

                        ForEach(Array(entry.sources.enumerated()), id: \.offset) { _, src in
                            HStack {
                                Text(src.source)
                                    .font(.system(size: 10))
                                    .foregroundColor(.veroOnSurfaceVariant)
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
                    }
                    Spacer(minLength: 0)
                }

                // Footer
                Text(relativeTime(from: entry.lastUpdated))
                    .font(.system(size: 7))
                    .foregroundColor(Color(hex: "#333333"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 6)
            }
            .padding(12)

            if !entry.isSubscribed {
                WidgetLockView()
            }
        }
        .widgetURL(widgetURL(for: "analytics"))
    }

    @ViewBuilder
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(.veroSubtle)
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
