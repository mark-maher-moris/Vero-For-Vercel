import WidgetKit
import SwiftUI

// MARK: - Data

struct LogEntry {
    let message: String
    let level: String
    let timestampMs: Int
}

struct LogsEntry: TimelineEntry {
    let date: Date
    let projectName: String
    let deployStatus: String
    let logs: [LogEntry]
    let isSubscribed: Bool
    let lastUpdated: Date?
    let isConfigured: Bool
    let maxRows: Int
}

// MARK: - Provider (Medium)

struct LogsMediumProvider: TimelineProvider {
    func placeholder(in context: Context) -> LogsEntry {
        LogsEntry(date: .now, projectName: "my-project", deployStatus: "READY",
                  logs: demoLogs(4), isSubscribed: true,
                  lastUpdated: .now, isConfigured: true, maxRows: 4)
    }

    func getSnapshot(in context: Context, completion: @escaping (LogsEntry) -> Void) {
        completion(loadEntry(maxRows: 4))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LogsEntry>) -> Void) {
        let entry = loadEntry(maxRows: 4)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry(maxRows: Int) -> LogsEntry {
        let d = UserDefaults.vero
        let projectId = d.veroString("vero_project_logs_id")
        let logsJson = d.veroString("vero_logs_data")
        let rawLogs = parseJSONArray(logsJson)
        let logs: [LogEntry] = rawLogs.prefix(maxRows).map { entry in
            LogEntry(
                message: (entry["message"] as? String ?? "").prefix(90).description,
                level: entry["level"] as? String ?? "info",
                timestampMs: entry["timestamp"] as? Int ?? 0
            )
        }
        return LogsEntry(
            date: .now,
            projectName: d.veroString("vero_logs_project_name", default: "Select Project"),
            deployStatus: d.veroString("vero_logs_deployment_status", default: "—"),
            logs: logs,
            isSubscribed: d.veroBool("vero_is_subscribed"),
            lastUpdated: ISO8601DateFormatter().date(from: d.veroString("vero_last_updated")),
            isConfigured: !projectId.isEmpty,
            maxRows: maxRows
        )
    }
}

// MARK: - Provider (Large)

struct LogsLargeProvider: TimelineProvider {
    func placeholder(in context: Context) -> LogsEntry {
        LogsEntry(date: .now, projectName: "my-project", deployStatus: "READY",
                  logs: demoLogs(8), isSubscribed: true,
                  lastUpdated: .now, isConfigured: true, maxRows: 8)
    }

    func getSnapshot(in context: Context, completion: @escaping (LogsEntry) -> Void) {
        completion(loadEntry(maxRows: 8))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LogsEntry>) -> Void) {
        let entry = loadEntry(maxRows: 8)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry(maxRows: Int) -> LogsEntry {
        let d = UserDefaults.vero
        let projectId = d.veroString("vero_project_logs_id")
        let logsJson = d.veroString("vero_logs_data")
        let rawLogs = parseJSONArray(logsJson)
        let logs: [LogEntry] = rawLogs.prefix(maxRows).map { entry in
            LogEntry(
                message: (entry["message"] as? String ?? "").prefix(100).description,
                level: entry["level"] as? String ?? "info",
                timestampMs: entry["timestamp"] as? Int ?? 0
            )
        }
        return LogsEntry(
            date: .now,
            projectName: d.veroString("vero_logs_project_name", default: "Select Project"),
            deployStatus: d.veroString("vero_logs_deployment_status", default: "—"),
            logs: logs,
            isSubscribed: d.veroBool("vero_is_subscribed"),
            lastUpdated: ISO8601DateFormatter().date(from: d.veroString("vero_last_updated")),
            isConfigured: !projectId.isEmpty,
            maxRows: maxRows
        )
    }
}

// MARK: - Shared Logs View

struct LogsWidgetView: View {
    let entry: LogsEntry

    var body: some View {
        ZStack {
            Color.veroSurface.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("LOGS")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.veroPrimary)
                    Text("·")
                        .foregroundColor(.veroSubtle)
                        .font(.system(size: 8))
                    Text(entry.projectName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Text(entry.deployStatus)
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundColor(statusColor(entry.deployStatus))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(statusColor(entry.deployStatus).opacity(0.12))
                        .cornerRadius(2)
                }
                .padding(.bottom, 6)

                if !entry.isConfigured {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "gear")
                                .foregroundColor(.veroMuted)
                            Text("Tap to configure")
                                .font(.system(size: 10))
                                .foregroundColor(.veroMuted)
                        }
                        Spacer()
                    }
                    Spacer()
                } else if entry.logs.isEmpty {
                    Spacer()
                    Text("No recent logs")
                        .font(.system(size: 10))
                        .foregroundColor(.veroSubtle)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    // Log rows
                    ForEach(Array(entry.logs.enumerated()), id: \.offset) { _, log in
                        HStack(alignment: .top, spacing: 6) {
                            Text(log.message.isEmpty ? "—" : log.message)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.veroOnSurfaceVariant)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if log.timestampMs > 0 {
                                Text(formatTimestamp(log.timestampMs))
                                    .font(.system(size: 8))
                                    .foregroundColor(.veroSubtle)
                            }
                        }
                        .padding(.vertical, 1)
                    }
                    Spacer(minLength: 0)
                }

                // Footer
                Text(relativeTime(from: entry.lastUpdated))
                    .font(.system(size: 7))
                    .foregroundColor(Color(hex: "#333333"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
            }
            .padding(10)

            if !entry.isSubscribed {
                WidgetLockView()
            }
        }
        .widgetURL(widgetURL(for: "logs"))
    }
}

// MARK: - Widget definitions

struct LogsMediumWidget: Widget {
    let kind = "LogsMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LogsMediumProvider()) { entry in
            LogsWidgetView(entry: entry)
        }
        .configurationDisplayName("Vero Logs")
        .description("Monitor the last 4 log entries from your latest deployment.")
        .supportedFamilies([.systemMedium])
    }
}

struct LogsLargeWidget: Widget {
    let kind = "LogsLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LogsLargeProvider()) { entry in
            LogsWidgetView(entry: entry)
        }
        .configurationDisplayName("Vero Logs (Large)")
        .description("Monitor the last 8 log entries from your latest deployment.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Demo data helper

private func demoLogs(_ count: Int) -> [LogEntry] {
    let messages = [
        "Build started", "Installing dependencies", "npm install",
        "Building project", "Compiling TypeScript", "Bundling assets",
        "Optimizing images", "Deploy complete"
    ]
    return (0..<count).map { i in
        LogEntry(message: messages[i % messages.count],
                 level: i == 2 ? "error" : "info",
                 timestampMs: Int(Date().timeIntervalSince1970 * 1000) - (i * 5000))
    }
}
