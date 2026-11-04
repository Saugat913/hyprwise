import WidgetKit
import SwiftUI

private let appGroupId = "group.com.hypr.hyprwise"

// MARK: - 1. Live Shift Tracker Widget

struct ShiftEntry: TimelineEntry {
    let date: Date
    let jobName: String
    let subtitle: String
    let isActive: Bool
    let isOnBreak: Bool
}

struct ShiftTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftEntry {
        ShiftEntry(date: Date(), jobName: "CAFE", subtitle: "02:15:30 • $62.50", isActive: true, isOnBreak: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftEntry) -> Void) {
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> ShiftEntry {
        let prefs = UserDefaults(suiteName: appGroupId)
        let job = prefs?.string(forKey: "widget_shift_job") ?? "NO ACTIVE SHIFT"
        let subtitle = prefs?.string(forKey: "widget_shift_subtitle") ?? "Tap to start a shift"
        let isActive = prefs?.bool(forKey: "widget_shift_active") ?? false && job != "NO ACTIVE SHIFT" && !job.isEmpty
        let isOnBreak = prefs?.bool(forKey: "widget_shift_is_on_break") ?? false

        return ShiftEntry(
            date: Date(),
            jobName: job,
            subtitle: subtitle,
            isActive: isActive,
            isOnBreak: isOnBreak
        )
    }
}

struct ShiftWidgetView: View {
    var entry: ShiftEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Status dot + Job title
            HStack(spacing: 6) {
                Circle()
                    .fill(entry.isActive ? (entry.isOnBreak ? Color(red: 0.96, green: 0.62, blue: 0.04) : Color(red: 0.09, green: 0.64, blue: 0.29)) : Color(red: 0.58, green: 0.64, blue: 0.72))
                    .frame(width: 8, height: 8)

                Text(entry.jobName.uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))
                    .lineLimit(1)
            }

            // Subtitle: Time & pay rates
            Text(entry.subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.39, green: 0.45, blue: 0.55))
                .lineLimit(1)

            Spacer(minLength: 0)

            if family == .systemMedium {
                if entry.isActive {
                    // Action Buttons Row: break | end
                    HStack(spacing: 10) {
                        Link(destination: URL(string: "hyprwise:///work/shift/live?action=break")!) {
                            Text(entry.isOnBreak ? "resume" : "break")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1)
                                )
                        }

                        Link(destination: URL(string: "hyprwise:///work/shift/live?action=end")!) {
                            Text("end")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(red: 0.86, green: 0.15, blue: 0.15))
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1)
                                )
                        }
                    }
                } else {
                    Link(destination: URL(string: "hyprwise:///work/shift/start")!) {
                        Text("start shift")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(Color(red: 0.06, green: 0.09, blue: 0.16))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(14)
        .widgetURL(URL(string: entry.isActive ? "hyprwise:///work/shift/live" : "hyprwise:///work/shift/start"))
    }
}

struct ShiftWidget: Widget {
    let kind: String = "ShiftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShiftTimelineProvider()) { entry in
            ShiftWidgetView(entry: entry)
                .background(Color.white)
        }
        .configurationDisplayName("Live Shift Tracker")
        .description("Track active work shifts, live earnings, breaks, and wage progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 2. Quick Actions Widget

struct QuickActionsEntry: TimelineEntry {
    let date: Date
}

struct QuickActionsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickActionsEntry {
        QuickActionsEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickActionsEntry) -> Void) {
        completion(QuickActionsEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickActionsEntry>) -> Void) {
        let timeline = Timeline(entries: [QuickActionsEntry(date: Date())], policy: .never)
        completion(timeline)
    }
}

struct QuickActionsWidgetView: View {
    var body: some View {
        HStack(spacing: 8) {
            // Income
            Link(destination: URL(string: "hyprwise:///money/add?type=income")!) {
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.86, green: 0.99, blue: 0.91))
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.down.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.09, green: 0.64, blue: 0.29))
                    }
                    Text("income")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))
                }
                .frame(maxWidth: .infinity)
            }

            // Expense
            Link(destination: URL(string: "hyprwise:///money/add?type=expense")!) {
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.89, blue: 0.89))
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.86, green: 0.15, blue: 0.15))
                    }
                    Text("expense")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))
                }
                .frame(maxWidth: .infinity)
            }

            // Lend
            Link(destination: URL(string: "hyprwise:///debts/add?type=lent")!) {
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.86, green: 0.92, blue: 1.0))
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.39, blue: 0.92))
                    }
                    Text("lend")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))
                }
                .frame(maxWidth: .infinity)
            }

            // Borrow
            Link(destination: URL(string: "hyprwise:///debts/add?type=borrowed")!) {
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.93, blue: 0.84))
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.92, green: 0.35, blue: 0.05))
                    }
                    Text("borrow")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
    }
}

struct QuickActionsWidget: Widget {
    let kind: String = "QuickActionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickActionsTimelineProvider()) { _ in
            QuickActionsWidgetView()
                .background(Color.white)
        }
        .configurationDisplayName("Quick Actions")
        .description("Instantly record income, expenses, loans, and borrowed money.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - 3. HyprAI Launcher Widget

struct HyprAiEntry: TimelineEntry {
    let date: Date
}

struct HyprAiTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HyprAiEntry {
        HyprAiEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (HyprAiEntry) -> Void) {
        completion(HyprAiEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HyprAiEntry>) -> Void) {
        let timeline = Timeline(entries: [HyprAiEntry(date: Date())], policy: .never)
        completion(timeline)
    }
}

struct HyprAiWidgetView: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.93, green: 0.95, blue: 1.0))
                    .frame(width: 46, height: 46)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.31, green: 0.27, blue: 0.90))
            }

            Text("hyprai")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .widgetURL(URL(string: "hyprwise:///assistant"))
    }
}

struct HyprAiWidget: Widget {
    let kind: String = "HyprAiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HyprAiTimelineProvider()) { _ in
            HyprAiWidgetView()
                .background(Color.white)
        }
        .configurationDisplayName("HyprAI")
        .description("Quick launch your Hyprwise AI financial assistant.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Bundle

@main
struct HyprwiseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ShiftWidget()
        QuickActionsWidget()
        HyprAiWidget()
    }
}
