import WidgetKit
import SwiftUI

// MARK: - Data

struct CountryItem {
    let code: String
    let name: String
    let visitors: Int
    let percentage: Int
}

struct CountriesEntry: TimelineEntry {
    let date: Date
    let projectName: String
    let countries: [CountryItem]
    let isSubscribed: Bool
    let isConfigured: Bool
    let lastUpdated: Date?
}

// MARK: - Provider

struct CountriesProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountriesEntry {
        CountriesEntry(date: .now, projectName: "my-project",
                       countries: demoCountries(), isSubscribed: true,
                       isConfigured: true, lastUpdated: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (CountriesEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountriesEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> CountriesEntry {
        let d = UserDefaults.vero
        let projectId = d.veroString("vero_project_countries_id")
        let json = d.veroString("vero_countries_data")
        let raw = parseJSONArray(json)
        let countries: [CountryItem] = raw.prefix(5).map { item in
            CountryItem(
                code: item["code"] as? String ?? "",
                name: item["name"] as? String ?? (item["code"] as? String ?? "Unknown"),
                visitors: item["visitors"] as? Int ?? 0,
                percentage: item["percentage"] as? Int ?? 0
            )
        }
        return CountriesEntry(
            date: .now,
            projectName: d.veroString("vero_countries_project_name", default: "Select Project"),
            countries: countries,
            isSubscribed: d.veroBool("vero_is_subscribed"),
            isConfigured: !projectId.isEmpty,
            lastUpdated: ISO8601DateFormatter().date(from: d.veroString("vero_last_updated"))
        )
    }
}

// MARK: - View

struct CountriesMediumView: View {
    let entry: CountriesEntry

    var body: some View {
        ZStack {
            Color.veroSurface.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("GEO")
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
                    Text(relativeTime(from: entry.lastUpdated))
                        .font(.system(size: 7))
                        .foregroundColor(.veroSubtle)
                }
                .padding(.bottom, 8)

                if !entry.isConfigured || entry.countries.isEmpty {
                    Spacer()
                    Text(entry.isConfigured ? "No traffic data" : "Tap to configure widget")
                        .font(.system(size: 10))
                        .foregroundColor(.veroSubtle)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    ForEach(Array(entry.countries.enumerated()), id: \.offset) { idx, country in
                        HStack(spacing: 8) {
                            Text(flagEmoji(country.code))
                                .font(.system(size: 14))

                            Text(country.name)
                                .font(.system(size: 10))
                                .foregroundColor(idx == 0 ? .white : .veroOnSurfaceVariant)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(formatNumber(country.visitors))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.veroPrimary)

                            Text("\(country.percentage)%")
                                .font(.system(size: 9))
                                .foregroundColor(.veroSubtle)
                                .frame(width: 28, alignment: .trailing)
                        }
                        .padding(.vertical, 2)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(10)

            if !entry.isSubscribed {
                WidgetLockView()
            }
        }
        .widgetURL(widgetURL(for: "countries"))
    }

    /// Convert ISO 3166-1 alpha-2 code to flag emoji
    private func flagEmoji(_ code: String) -> String {
        let base: UInt32 = 127397
        return code.uppercased().unicodeScalars
            .compactMap { UnicodeScalar(base + $0.value) }
            .map { String($0) }
            .joined()
    }
}

// MARK: - Widget definition

struct CountriesMediumWidget: Widget {
    let kind = "CountriesMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountriesProvider()) { entry in
            CountriesMediumView(entry: entry)
        }
        .configurationDisplayName("Vero Geo Traffic")
        .description("Top countries driving traffic to your project. Requires Vercel Analytics.")
        .supportedFamilies([.systemMedium])
    }
}

private func demoCountries() -> [CountryItem] {
    [
        CountryItem(code: "US", name: "United States", visitors: 1_200, percentage: 42),
        CountryItem(code: "GB", name: "United Kingdom", visitors: 430, percentage: 15),
        CountryItem(code: "DE", name: "Germany", visitors: 290, percentage: 10),
        CountryItem(code: "IN", name: "India", visitors: 210, percentage: 7),
        CountryItem(code: "CA", name: "Canada", visitors: 180, percentage: 6),
    ]
}
