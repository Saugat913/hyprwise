import WidgetKit
import SwiftUI
import UIKit

private let appGroupId = "group.com.hypr.hyprwise"

// MARK: - Design Tokens (Exact parity with lib/core/theme/app_palette.dart)

private extension Color {
    static func hw(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
    static let hwPage = hw(0xF6F6F6, 0x0F0F11)
    static let hwCard = hw(0xFFFFFF, 0x18181B)
    static let hwHero = hw(0x141417, 0x18181C)
    static let hwInk = hw(0x0F0F11, 0xF4F4F6)
    static let hwMuted = hw(0x59615D, 0x9B9BA6)
    static let hwHairline = hw(0xE6E8E7, 0x27272A)
    static let hwFill = hw(0xEDEEED, 0x232326)
    static let hwGreen = hw(0x1F7A45, 0x4CC38A)
    static let hwGreenBg = hw(0xE3F3EA, 0x16301F)
    static let hwRed = hw(0xB42318, 0xF2766B)
    static let hwRedBg = hw(0xFDECEB, 0x381918)
    static let hwAmber = hw(0x9A5B00, 0xF0B24A)
    static let hwAmberBg = hw(0xFFF1D6, 0x3A2C10)
    static let hwBrand = hw(0xFF6500, 0xFF6500)
    static let hwBrandText = hw(0xB84400, 0xFF8533)
    static let hwBrandBg = hw(0xFFF0E6, 0x2E1303)
}

// MARK: - Exact HugeIcons SVG Vector Renderer (1:1 parity with Flutter & Android widgets)

private enum HwIconKind {
    case briefcase
    case coffee
    case play
    case stop
    case income
    case expense
    case lend
    case borrow
    case sparkles

    var svgPaths: [String] {
        switch self {
        case .briefcase:
            return [
                "M 2.00127 8.5 L 1.99911 13.997 C 1.99782 17.2979 1.99717 18.9484 3.02235 19.974 C 4.04754 20.9996 5.69801 20.9996 8.99895 20.9997 L 15 20.9998 C 18.2994 20.9999 19.949 21 20.9741 19.9751 C 21.9992 18.9502 21.9996 17.3005 22.0002 14.0012 L 22.0013 8.5",
                "M 8.49857 6.5 C 8.49857 5.09554 8.49857 4.39331 8.83563 3.88886 C 8.98154 3.67048 9.16904 3.48298 9.38743 3.33706 C 9.89187 3 10.5941 3 11.9986 3 C 13.403 3 14.1053 3 14.6097 3.33706 C 14.8281 3.48298 15.0156 3.67048 15.1615 3.88886 C 15.4986 4.39331 15.4986 5.09554 15.4986 6.5",
                "M 19.998 6.50016 L 3.99885 6.5 C 2.8944 6.50007 1.99876 7.39568 1.99866 8.50013 C 1.99876 10.7091 3.79005 12.5004 5.99901 12.5006 H 17.9978 C 20.2068 12.5005 21.998 10.7093 21.9981 8.5003 C 21.998 7.39582 21.1024 6.50023 19.998 6.50016 Z",
                "M 9.99857 12.5 V 13.5 C 9.99857 13.965 9.99857 14.1975 10.0497 14.3882 C 10.1884 14.9059 10.5927 15.3102 11.1103 15.4489 C 11.3011 15.5 11.5336 15.5 11.9986 15.5 C 12.4636 15.5 12.696 15.5 12.8868 15.4489 C 13.4044 15.3102 13.8088 14.9059 13.9475 14.3882 C 13.9986 14.1975 13.9986 13.965 13.9986 13.5 V 12.5",
            ]
        case .coffee:
            return [
                "M 5 7 L 6.7602 17.4048 C 7.06616 19.2134 7.21914 20.1177 7.76007 20.7417 C 9.21438 22.4194 14.7856 22.4194 16.2399 20.7417 C 16.7809 20.1177 16.9338 19.2134 17.2398 17.4048 L 19 7",
                "M 5 7 L 5.74278 5.2876 C 6.35168 3.88385 6.65613 3.18197 7.29101 2.7856 C 8.88049 1.79324 14.9452 1.68444 16.709 2.7856 C 17.3439 3.18197 17.6483 3.88385 18.2572 5.2876 L 19 7",
                "M 4 7 H 20",
            ]
        case .play:
            return [
                "M 18.8906 12.846 C 18.5371 14.189 16.8667 15.138 13.5257 17.0361 C 10.296 18.8709 8.6812 19.7884 7.37983 19.4196 C 6.8418 19.2671 6.35159 18.9776 5.95624 18.5787 C 5 17.6139 5 15.7426 5 12 C 5 8.2574 5 6.3861 5.95624 5.42132 C 6.35159 5.02245 6.8418 4.73288 7.37983 4.58042 C 8.6812 4.21165 10.296 5.12907 13.5257 6.96393 C 16.8667 8.86197 18.5371 9.811 18.8906 11.154 C 19.0365 11.7084 19.0365 12.2916 18.8906 12.846 Z",
            ]
        case .stop:
            return [
                "M 4 12 C 4 8.72077 4 7.08116 4.81382 5.91891 C 5.1149 5.48891 5.48891 5.1149 5.91891 4.81382 C 7.08116 4 8.72077 4 12 4 C 15.2792 4 16.9188 4 18.0811 4.81382 C 18.5111 5.1149 18.8851 5.48891 19.1862 5.91891 C 20 7.08116 20 8.72077 20 12 C 20 15.2792 20 16.9188 19.1862 18.0811 C 18.8851 18.5111 18.5111 18.8851 18.0811 19.1862 C 16.9188 20 15.2792 20 12 20 C 8.72077 20 7.08116 20 5.91891 19.1862 C 5.48891 18.8851 5.1149 18.5111 4.81382 18.0811 C 4 16.9188 4 15.2792 4 12 Z",
            ]
        case .income:
            return [
                "M 15 17.3497 C 15 17.3497 8.06166 17.8924 7.08461 16.9154 C 6.10755 15.9383 6.65037 9 6.65037 9 M 7.5 16.5 L 17.5 6.5",
            ]
        case .expense:
            return [
                "M 9 6.65032 C 9 6.65032 15.9383 6.10759 16.9154 7.08463 C 17.8924 8.06167 17.3496 15 17.3496 15 M 16.5 7.5 L 6.5 17.5",
            ]
        case .lend:
            return [
                "M 14.4998 14.001 C 14.4998 15.3817 13.3805 16.501 11.9998 16.501 C 10.619 16.501 9.49976 15.3817 9.49976 14.001 C 9.49976 12.6203 10.619 11.501 11.9998 11.501 C 13.3805 11.501 14.4998 12.6203 14.4998 14.001 Z",
                "M 8 7.88972 C 6.88069 7.88442 5.55979 7.75835 3.87798 7.42461 C 2.92079 7.23467 2 7.94632 2 8.92217 V 18.9392 C 2 19.6275 2.47265 20.232 3.1448 20.3802 C 10.1096 21.9161 11.2491 20.1104 16 20.1104 C 17.5107 20.1104 18.7361 20.253 19.6762 20.4305 C 20.7719 20.6375 22 19.7984 22 18.6833 V 8.90853 C 22 8.34037 21.6756 7.82599 21.1329 7.6578 C 20.3228 7.40675 18.9452 7.08767 17 7.00293",
                "M 2 11.001 C 3.95133 11.001 5.70483 9.40605 5.92901 7.75514 M 18.5005 7.50098 C 18.5005 9.54062 20.2655 11.47 22 11.47 M 22 17.001 C 20.1009 17.001 18.2601 18.3112 18.102 20.0993 M 6.00049 20.4971 C 6.00049 18.2879 4.20963 16.4971 2.00049 16.4971",
                "M 9.5 5.50098 C 9.5 5.50098 11.2998 3.00098 12 3.00098 M 14.5 5.50098 C 14.5 5.50098 12.7002 3.00098 12 3.00098 M 12 3.00098 L 12 8.50098",
            ]
        case .borrow:
            return [
                "M 14.4998 14.001 C 14.4998 15.3817 13.3805 16.501 11.9998 16.501 C 10.619 16.501 9.49976 15.3817 9.49976 14.001 C 9.49976 12.6203 10.619 11.501 11.9998 11.501 C 13.3805 11.501 14.4998 12.6203 14.4998 14.001 Z",
                "M 17 7.00293 C 18.9452 7.08767 20.3228 7.40675 21.1329 7.6578 C 21.6756 7.82599 22 8.34037 22 8.90853 V 18.6833 C 22 19.7984 20.7719 20.6375 19.6762 20.4305 C 18.7361 20.253 17.5107 20.1104 16 20.1104 C 11.2491 20.1104 10.1096 21.9161 3.1448 20.3802 C 2.47265 20.232 2 19.6275 2 18.9392 V 8.92217 C 2 7.94632 2.92079 7.23467 3.87798 7.42461 C 5.31598 7.70997 6.49012 7.8435 7.5 7.87953",
                "M 2 11.001 C 3.95133 11.001 5.70483 9.40605 5.92901 7.75514 M 18.5005 7.50098 C 18.5005 9.54062 20.2655 11.47 22 11.47 M 22 17.001 C 20.1009 17.001 18.2601 18.3112 18.102 20.0993 M 6.00049 20.4971 C 6.00049 18.2879 4.20963 16.4971 2.00049 16.4971",
                "M 12 8.50098 L 12 3.00098 M 12 8.50098 C 12.7002 8.50098 14.5 6.00098 14.5 6.00098 M 12 8.50098 C 11.2998 8.50098 9.5 6.00098 9.5 6.00098",
            ]
        case .sparkles:
            return [
                "M 15 2 L 15.5387 4.39157 C 15.9957 6.42015 17.5798 8.00431 19.6084 8.46127 L 22 9 L 19.6084 9.53873 C 17.5798 9.99569 15.9957 11.5798 15.5387 13.6084 L 15 16 L 14.4613 13.6084 C 14.0043 11.5798 12.4202 9.99569 10.3916 9.53873 L 8 9 L 10.3916 8.46127 C 12.4201 8.00431 14.0043 6.42015 14.4613 4.39158 L 15 2 Z",
                "M 7 12 L 7.38481 13.7083 C 7.71121 15.1572 8.84275 16.2888 10.2917 16.6152 L 12 17 L 10.2917 17.3848 C 8.84275 17.7112 7.71121 18.8427 7.38481 20.2917 L 7 22 L 6.61519 20.2917 C 6.28879 18.8427 5.15725 17.7112 3.70827 17.3848 L 2 17 L 3.70827 16.6152 C 5.15725 16.2888 6.28879 15.1573 6.61519 13.7083 L 7 12 Z",
            ]
        }
    }

    var extraEllipse: CGRect? {
        switch self {
        case .coffee: return CGRect(x: 10, y: 12, width: 4, height: 5)
        default: return nil
        }
    }
}

private struct HwSvgShape: Shape {
    let kind: HwIconKind

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 24.0
        let sy = rect.height / 24.0
        var path = Path()

        for d in kind.svgPaths {
            let tokens = d.split(separator: " ").map(String.init)
            var i = 0
            var cur = CGPoint.zero
            func nextVal() -> CGFloat {
                guard i < tokens.count else { return 0 }
                let v = Double(tokens[i]) ?? 0
                i += 1
                return CGFloat(v)
            }
            while i < tokens.count {
                let cmd = tokens[i]
                i += 1
                switch cmd {
                case "M":
                    let x = nextVal(), y = nextVal()
                    cur = CGPoint(x: x, y: y)
                    path.move(to: CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy))
                case "L":
                    let x = nextVal(), y = nextVal()
                    cur = CGPoint(x: x, y: y)
                    path.addLine(to: CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy))
                case "H":
                    let x = nextVal()
                    cur = CGPoint(x: x, y: cur.y)
                    path.addLine(to: CGPoint(x: rect.minX + x * sx, y: rect.minY + cur.y * sy))
                case "V":
                    let y = nextVal()
                    cur = CGPoint(x: cur.x, y: y)
                    path.addLine(to: CGPoint(x: rect.minX + cur.x * sx, y: rect.minY + y * sy))
                case "C":
                    let x1 = nextVal(), y1 = nextVal()
                    let x2 = nextVal(), y2 = nextVal()
                    let x = nextVal(), y = nextVal()
                    cur = CGPoint(x: x, y: y)
                    path.addCurve(
                        to: CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy),
                        control1: CGPoint(x: rect.minX + x1 * sx, y: rect.minY + y1 * sy),
                        control2: CGPoint(x: rect.minX + x2 * sx, y: rect.minY + y2 * sy)
                    )
                case "Z":
                    path.closeSubpath()
                default:
                    break
                }
            }
        }

        if let e = kind.extraEllipse {
            path.addEllipse(in: CGRect(
                x: rect.minX + e.minX * sx,
                y: rect.minY + e.minY * sy,
                width: e.width * sx,
                height: e.height * sy
            ))
        }
        return path
    }
}

private struct HwVectorIcon: View {
    let kind: HwIconKind
    let size: CGFloat
    let color: Color

    var body: some View {
        HwSvgShape(kind: kind)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: max(1.3, size * (1.7 / 24.0)),
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(width: size, height: size)
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

private extension View {
    /// iOS 17+ requires containerBackground; without it the widget renders blank.
    @ViewBuilder func hwWidgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(Color.hwCard, for: .widget)
        } else {
            background(Color.hwCard)
        }
    }
}

private extension WidgetConfiguration {
    /// Prevents iOS 17+ system margins from double-padding custom card layouts.
    func hwDisableContentMargins() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return contentMarginsDisabled()
        } else {
            return self
        }
    }
}

// MARK: - Shared Formatting Helpers

private func hwFormatDuration(_ totalSeconds: Int) -> String {
    let clamped = max(0, totalSeconds)
    let h = clamped / 3600
    let m = (clamped % 3600) / 60
    let s = clamped % 60
    return String(format: "%02d:%02d:%02d", h, m, s)
}

private func hwComputeEarningsMinor(
    workedSeconds: Int,
    rateMinor: Int,
    otThresholdMin: Int,
    otRateMinor: Int
) -> Int {
    guard workedSeconds > 0, rateMinor > 0 else { return 0 }
    let thresholdSec = otThresholdMin * 60
    if otThresholdMin > 0 && otRateMinor > 0 && workedSeconds > thresholdSec {
        let regPay = (Double(thresholdSec) * Double(rateMinor)) / 3600.0
        let otPay = (Double(workedSeconds - thresholdSec) * Double(otRateMinor)) / 3600.0
        return Int((regPay + otPay).rounded())
    }
    return Int(((Double(workedSeconds) * Double(rateMinor)) / 3600.0).rounded())
}

private func hwFormatMoney(minorUnits: Int, symbol: String, currencyCode: String) -> String {
    let major = Double(minorUnits) / 100.0
    let isJpy = currencyCode.uppercased() == "JPY"
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: "en_US")
    formatter.minimumFractionDigits = (isJpy && minorUnits % 100 == 0) ? 0 : 2
    formatter.maximumFractionDigits = (isJpy && minorUnits % 100 == 0) ? 0 : 2
    let numStr = formatter.string(from: NSNumber(value: major)) ?? String(format: "%.2f", major)
    return "\(symbol)\(numStr)"
}

private func hwReadInt(_ prefs: UserDefaults?, _ key: String) -> Int {
    guard let raw = prefs?.object(forKey: key) else { return 0 }
    if let n = raw as? NSNumber { return n.intValue }
    if let s = raw as? String { return Int(s) ?? 0 }
    return 0
}

private func hwReadInt64(_ prefs: UserDefaults?, _ key: String) -> Int64 {
    guard let raw = prefs?.object(forKey: key) else { return 0 }
    if let n = raw as? NSNumber { return n.int64Value }
    if let s = raw as? String { return Int64(s) ?? 0 }
    return 0
}

// MARK: - 1. Live Shift Tracker Widget

struct ShiftEntry: TimelineEntry {
    let date: Date
    let jobName: String
    let subtitle: String
    let isActive: Bool
    let isOnBreak: Bool
    let effectiveStartDate: Date
    let pausedTimerText: String
    let earningsText: String
    let breakMinutes: Int
}

struct ShiftTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftEntry {
        ShiftEntry(
            date: Date(),
            jobName: "Cafe Shift",
            subtitle: "$25.00/h",
            isActive: true,
            isOnBreak: false,
            effectiveStartDate: Date().addingTimeInterval(-8130),
            pausedTimerText: "02:15:30",
            earningsText: "$56.46",
            breakMinutes: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftEntry) -> Void) {
        completion(buildEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftEntry>) -> Void) {
        let now = Date()
        let baseEntry = buildEntry(at: now)

        // When actively working, schedule 60 minute-by-minute timeline entries so
        // live earnings refresh continuously every minute while WidgetKit's native
        // `Text(effectiveStartDate, style: .timer)` ticks live every second!
        if baseEntry.isActive && !baseEntry.isOnBreak {
            var entries: [ShiftEntry] = []
            entries.reserveCapacity(60)
            for minuteOffset in 0..<60 {
                let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now) ?? now
                entries.append(buildEntry(at: entryDate))
            }
            completion(Timeline(entries: entries, policy: .atEnd))
        } else {
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
            completion(Timeline(entries: [baseEntry], policy: .after(nextUpdate)))
        }
    }

    private func buildEntry(at date: Date) -> ShiftEntry {
        let prefs = UserDefaults(suiteName: appGroupId)
        let job = (prefs?.string(forKey: "widget_shift_job") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let isActive = (prefs?.bool(forKey: "widget_shift_active") ?? false) && !job.isEmpty && job != "NO ACTIVE SHIFT"
        let isOnBreak = prefs?.bool(forKey: "widget_shift_is_on_break") ?? false

        if !isActive {
            let defaultJob = (prefs?.string(forKey: "widget_default_job") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let defaultRate = (prefs?.string(forKey: "widget_default_rate_label") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let storedSub = (prefs?.string(forKey: "widget_shift_subtitle") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            let title = defaultJob.isEmpty ? "Shift Tracker" : defaultJob
            let subtitle: String
            if !defaultJob.isEmpty && !defaultRate.isEmpty {
                subtitle = "Ready to clock in · \(defaultRate)"
            } else if !storedSub.isEmpty {
                subtitle = storedSub
            } else {
                subtitle = "Tap to start tracking"
            }

            return ShiftEntry(
                date: date,
                jobName: title,
                subtitle: subtitle,
                isActive: false,
                isOnBreak: false,
                effectiveStartDate: date,
                pausedTimerText: "00:00:00",
                earningsText: "",
                breakMinutes: 0
            )
        }

        let effectiveStartMs = hwReadInt64(prefs, "widget_shift_effective_start_ms")
        let storedWorkedSec = hwReadInt(prefs, "widget_shift_worked_seconds")
        let breakMinutes = hwReadInt(prefs, "widget_shift_break_minutes")
        let rateMinor = hwReadInt(prefs, "widget_shift_rate_minor")
        let otThresholdMin = hwReadInt(prefs, "widget_shift_ot_threshold_min")
        let otRateMinor = hwReadInt(prefs, "widget_shift_ot_rate_minor")
        let currencyCode = prefs?.string(forKey: "widget_shift_currency_code") ?? "USD"
        let currencySymbol = prefs?.string(forKey: "widget_shift_currency_symbol") ?? "$"
        let rateLabel = (prefs?.string(forKey: "widget_shift_rate_label") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let storedEarnings = (prefs?.string(forKey: "widget_shift_earnings_label") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        let effectiveStartDate: Date
        if effectiveStartMs > 0 {
            effectiveStartDate = Date(timeIntervalSince1970: TimeInterval(effectiveStartMs) / 1000.0)
        } else {
            effectiveStartDate = date.addingTimeInterval(-TimeInterval(max(0, storedWorkedSec)))
        }

        let workedSec: Int
        if !isOnBreak {
            workedSec = max(0, Int(date.timeIntervalSince(effectiveStartDate)))
        } else {
            workedSec = max(0, storedWorkedSec)
        }

        let earningsText: String
        if rateMinor > 0 {
            let minor = hwComputeEarningsMinor(
                workedSeconds: workedSec,
                rateMinor: rateMinor,
                otThresholdMin: otThresholdMin,
                otRateMinor: otRateMinor
            )
            earningsText = hwFormatMoney(minorUnits: minor, symbol: currencySymbol, currencyCode: currencyCode)
        } else if !storedEarnings.isEmpty {
            earningsText = storedEarnings
        } else {
            earningsText = hwFormatMoney(minorUnits: 0, symbol: currencySymbol, currencyCode: currencyCode)
        }

        var parts: [String] = []
        if !rateLabel.isEmpty { parts.append(rateLabel) }
        if breakMinutes > 0 { parts.append("\(breakMinutes)m break") }
        let metaSubtitle = parts.isEmpty ? (isOnBreak ? "Timer paused" : "Shift in progress") : parts.joined(separator: " · ")

        return ShiftEntry(
            date: date,
            jobName: job,
            subtitle: metaSubtitle,
            isActive: true,
            isOnBreak: isOnBreak,
            effectiveStartDate: effectiveStartDate,
            pausedTimerText: hwFormatDuration(workedSec),
            earningsText: earningsText,
            breakMinutes: breakMinutes
        )
    }
}

private struct ShiftStatusChip: View {
    let isActive: Bool
    let isOnBreak: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? (isOnBreak ? Color.hwAmber : Color.hwGreen) : Color.hwMuted)
                .frame(width: 6, height: 6)
            Text(isActive ? (isOnBreak ? "On Break" : "Live") : "Ready")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(isActive ? (isOnBreak ? Color.hwAmber : Color.hwGreen) : Color.hwMuted)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(isActive ? (isOnBreak ? Color.hwAmberBg : Color.hwGreenBg) : Color.hwFill)
        .cornerRadius(8)
    }
}

struct ShiftWidgetView: View {
    var entry: ShiftEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Row: IconTile + Stacked Job Title & Subtitle + StatusChip
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.hwFill)
                        .frame(width: 34, height: 34)
                    HwVectorIcon(kind: .briefcase, size: 17, color: Color.hwInk)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.jobName)
                        .font(.system(size: family == .systemSmall ? 13.5 : 14, weight: .bold))
                        .foregroundColor(Color.hwInk)
                        .lineLimit(1)
                    Text(entry.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.hwMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                if family == .systemMedium {
                    ShiftStatusChip(isActive: entry.isActive, isOnBreak: entry.isOnBreak)
                }
            }

            if entry.isActive {
                // Sleek inner metric container (matches Android widget_shift_live_row)
                if family == .systemMedium {
                    HStack(alignment: .center, spacing: 8) {
                        liveTimerText(size: 20)
                        Spacer(minLength: 4)
                        earningsPill
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.hwFill)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.hwHairline, lineWidth: 0.75)
                    )
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        liveTimerText(size: 19)
                        HStack(spacing: 6) {
                            earningsPill
                            ShiftStatusChip(isActive: entry.isActive, isOnBreak: entry.isOnBreak)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.hwFill)
                    .cornerRadius(10)
                }
            } else if family == .systemSmall {
                ShiftStatusChip(isActive: false, isOnBreak: false)
            }

            // Bottom Action Bar (zero dead middle void)
            if family == .systemMedium {
                if entry.isActive {
                    HStack(spacing: 8) {
                        Link(destination: URL(string: "hyprwise:///work/shift/live?action=break")!) {
                            HStack(spacing: 5) {
                                HwVectorIcon(
                                    kind: entry.isOnBreak ? .play : .coffee,
                                    size: 14,
                                    color: Color.hwInk
                                )
                                Text(entry.isOnBreak ? "Resume" : "Break")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(Color.hwInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.hwFill)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.hwHairline, lineWidth: 1)
                            )
                        }

                        Link(destination: URL(string: "hyprwise:///work/shift/live?action=end")!) {
                            HStack(spacing: 5) {
                                HwVectorIcon(kind: .stop, size: 13, color: Color.hwRed)
                                Text("End")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(Color.hwRed)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.hwRedBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.hwRed.opacity(0.45), lineWidth: 1)
                            )
                        }
                    }
                } else {
                    Link(destination: URL(string: "hyprwise:///work/shift/start")!) {
                        HStack(spacing: 6) {
                            HwVectorIcon(kind: .play, size: 13, color: Color.hwCard)
                            Text("Start Shift")
                                .font(.system(size: 12.5, weight: .bold))
                        }
                        .foregroundColor(Color.hwCard)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.hwInk)
                        .cornerRadius(12)
                    }
                }
            } else if !entry.isActive {
                HStack(spacing: 5) {
                    HwVectorIcon(kind: .play, size: 12.5, color: Color.hwCard)
                    Text("Start Shift")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color.hwCard)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Color.hwInk)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .widgetURL(URL(string: entry.isActive ? "hyprwise:///work/shift/live" : "hyprwise:///work/shift/start"))
    }

    @ViewBuilder
    private func liveTimerText(size: CGFloat) -> some View {
        if entry.isOnBreak {
            Text(entry.pausedTimerText)
                .font(.system(size: size, weight: .bold, design: .monospaced))
                .foregroundColor(Color.hwMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        } else {
            Text(entry.effectiveStartDate, style: .timer)
                .font(.system(size: size, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(Color.hwInk)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var earningsPill: some View {
        Text(entry.earningsText)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(Color.hwGreen)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.hwGreenBg)
            .cornerRadius(8)
            .lineLimit(1)
    }
}

struct ShiftWidget: Widget {
    let kind: String = "ShiftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShiftTimelineProvider()) { entry in
            ShiftWidgetView(entry: entry)
                .hwWidgetBackground()
        }
        .hwDisableContentMargins()
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
    func placeholder(in context: Context) -> QuickActionsEntry { QuickActionsEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (QuickActionsEntry) -> Void) {
        completion(QuickActionsEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickActionsEntry>) -> Void) {
        completion(Timeline(entries: [QuickActionsEntry(date: Date())], policy: .never))
    }
}

private struct QuickActionTile: View {
    let title: String
    let icon: HwIconKind
    let fg: Color
    let bg: Color
    let destination: String

    var body: some View {
        Link(destination: URL(string: destination)!) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(bg)
                        .frame(width: 34, height: 34)
                    HwVectorIcon(kind: icon, size: 18, color: fg)
                }
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.hwInk)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 8)
            .background(Color.hwFill)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.hwHairline, lineWidth: 0.75)
            )
        }
    }
}

struct QuickActionsWidgetView: View {
    var body: some View {
        HStack(spacing: 6) {
            QuickActionTile(
                title: "Income",
                icon: .income,
                fg: Color.hwGreen,
                bg: Color.hwGreenBg,
                destination: "hyprwise:///money/add?type=income"
            )
            QuickActionTile(
                title: "Expense",
                icon: .expense,
                fg: Color.hwRed,
                bg: Color.hwRedBg,
                destination: "hyprwise:///money/add?type=expense"
            )
            QuickActionTile(
                title: "Lend",
                icon: .lend,
                fg: Color.hwAmber,
                bg: Color.hwAmberBg,
                destination: "hyprwise:///debts/add?type=lent"
            )
            QuickActionTile(
                title: "Borrow",
                icon: .borrow,
                fg: Color.hwBrandText,
                bg: Color.hwBrandBg,
                destination: "hyprwise:///debts/add?type=borrowed"
            )
        }
        .padding(8)
    }
}

struct QuickActionsWidget: Widget {
    let kind: String = "QuickActionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickActionsTimelineProvider()) { _ in
            QuickActionsWidgetView()
                .hwWidgetBackground()
        }
        .hwDisableContentMargins()
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
    func placeholder(in context: Context) -> HyprAiEntry { HyprAiEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (HyprAiEntry) -> Void) {
        completion(HyprAiEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HyprAiEntry>) -> Void) {
        completion(Timeline(entries: [HyprAiEntry(date: Date())], policy: .never))
    }
}

struct HyprAiWidgetView: View {
    private var logoImage: UIImage? {
        if let url = Bundle.main.url(forResource: "HyprwiseMark", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let img = UIImage(data: data) {
            return img
        }
        return UIImage(named: "HyprwiseMark")
    }

    var body: some View {
        VStack(spacing: 8) {
            if let img = logoImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.hwBrandBg)
                        .frame(width: 50, height: 50)
                    HwVectorIcon(kind: .sparkles, size: 24, color: Color.hwBrand)
                }
            }

            VStack(spacing: 2) {
                Text("HyprAI")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.hwInk)

                Text("Ask assistant")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color.hwMuted)
            }
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
                .hwWidgetBackground()
        }
        .hwDisableContentMargins()
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
