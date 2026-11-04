import WidgetKit
import SwiftUI
import UIKit

private let appGroupId = "group.com.hypr.hyprwise"

// MARK: - Design tokens (mirror lib/core/theme/app_palette.dart, light + dark)

private extension Color {
    static func hw(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
    static let hwCard = hw(0xFFFFFF, 0x18181B)
    static let hwInk = hw(0x0F0F11, 0xF4F4F6)
    static let hwMuted = hw(0x7A827E, 0x8F8F99)
    static let hwHairline = hw(0xE6E8E7, 0x27272A)
    static let hwFill = hw(0xEDEEED, 0x232326)
    static let hwGreen = hw(0x1F7A45, 0x4CC38A)
    static let hwGreenBg = hw(0xE3F3EA, 0x16301F)
    static let hwRed = hw(0xB42318, 0xF2766B)
    static let hwRedBg = hw(0xFDE7E4, 0x3A1714)
    static let hwAmber = hw(0xF59E0B, 0xF0B24A)
    static let hwAmberBg = hw(0xFFF1D6, 0x3A2C10)
    static let hwBrand = hw(0xFF6500, 0xFF8533)
    static let hwBrandBg = hw(0xFFF0E6, 0x2E1303)
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

private extension View {
    /// iOS 17+ requires containerBackground; without it the widget renders blank.
    @ViewBuilder func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(Color.hwCard, for: .widget)
        } else {
            background(Color.hwCard)
        }
    }
}

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
                    .fill(entry.isActive ? (entry.isOnBreak ? .hwAmber : .hwGreen) : .hwMuted)
                    .frame(width: 8, height: 8)

                Text(entry.jobName.uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.hwInk)
                    .lineLimit(1)
            }

            // Subtitle: Time & pay rates
            Text(entry.subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.hwMuted)
                .lineLimit(1)

            Spacer(minLength: 0)

            if family == .systemMedium {
                if entry.isActive {
                    // Action Buttons Row: break | end
                    HStack(spacing: 10) {
                        Link(destination: URL(string: "hyprwise:///work/shift/live?action=break")!) {
                            Text(entry.isOnBreak ? "resume" : "break")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.hwInk)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(.hwFill)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.hwHairline, lineWidth: 1)
                                )
                        }

                        Link(destination: URL(string: "hyprwise:///work/shift/live?action=end")!) {
                            Text("end")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.hwRed)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(.hwFill)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.hwHairline, lineWidth: 1)
                                )
                        }
                    }
                } else {
                    Link(destination: URL(string: "hyprwise:///work/shift/start")!) {
                        Text("start shift")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(.hwCard)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(.hwInk)
                            .cornerRadius(12)
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
                .widgetBackground()
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
                            .fill(.hwGreenBg)
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.down.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.hwGreen)
                    }
                    Text("income")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.hwInk)
                }
                .frame(maxWidth: .infinity)
            }

            // Expense
            Link(destination: URL(string: "hyprwise:///money/add?type=expense")!) {
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(.hwRedBg)
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.hwRed)
                    }
                    Text("expense")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.hwInk)
                }
                .frame(maxWidth: .infinity)
            }

            // Lend
            Link(destination: URL(string: "hyprwise:///debts/add?type=lent")!) {
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(.hwAmberBg)
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.hwAmber)
                    }
                    Text("lend")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.hwInk)
                }
                .frame(maxWidth: .infinity)
            }

            // Borrow
            Link(destination: URL(string: "hyprwise:///debts/add?type=borrowed")!) {
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(.hwBrandBg)
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.hwBrand)
                    }
                    Text("borrow")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.hwInk)
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
                .widgetBackground()
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
                    .fill(.hwBrandBg)
                    .frame(width: 46, height: 46)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.hwBrand)
            }

            Text("hyprai")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.hwInk)
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
                .widgetBackground()
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
