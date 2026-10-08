import AppKit
import SwiftUI

/// 日付は地域・カレンダー設定に従い、時計形式と英語の曜日だけを固定する。
enum DashboardFormatting {
    static func clock(_ date: Date, format: ClockFormat,
                      timeZone: TimeZone = .autoupdatingCurrent) -> (time: String, period: String?) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = format == .twentyFourHour ? "HH:mm" : "hh:mm"
        let time = formatter.string(from: date)
        guard format == .twelveHour else { return (time, nil) }
        formatter.dateFormat = "a"
        return (time, formatter.string(from: date))
    }

    static func date(_ date: Date, locale: Locale = .autoupdatingCurrent,
                     calendar: Calendar = .autoupdatingCurrent,
                     timeZone: TimeZone = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("yMd")
        let localDate = formatter.string(from: date)
            .replacingOccurrences(of: "\\s*/\\s*", with: " / ", options: .regularExpression)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "EEE"
        return "\(localDate) \(formatter.string(from: date))"
    }
}

@MainActor
struct RoomDashboardView: View {
    @ObservedObject var store: RoomStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            GeometryReader { geometry in
                let scale = max(0.01, min(geometry.size.width / 1000, geometry.size.height / 562.5))
                ZStack {
                    Color.black
                    if store.settings.showsMainRow {
                        HStack(alignment: .center, spacing: 30 * scale) {
                            if store.settings.showClock {
                                clock(timeline.date, scale: scale)
                            }
                            if store.settings.showTemperature {
                                metric(symbol: "thermometer.medium", title: "室温",
                                       value: store.reading?.temperatureCelsius.map { String(format: "%.1f", $0) } ?? "—",
                                       unit: "°C", scale: scale)
                            }
                            if store.settings.showHumidity {
                                metric(symbol: "humidity", title: "湿度",
                                       value: store.reading?.relativeHumidity.map { String(format: "%.0f", $0) } ?? "—",
                                       unit: "%", scale: scale)
                            }
                        }
                        .padding(.horizontal, 28 * scale)
                        .padding(.vertical, 24 * scale)
                        .overlay(Rectangle().strokeBorder(.white.opacity(0.72), lineWidth: 5 * scale))
                        .fixedSize()
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                    if store.settings.showDate {
                        Text(DashboardFormatting.date(timeline.date))
                            .font(DashboardFont.date(size: 18 * scale))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: geometry.size.width * 0.9)
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.835)
                    }
                    if store.settings.showsMeasurements {
                        status
                            .font(.system(size: 8 * scale, weight: .medium))
                            .foregroundStyle(.white.opacity(0.38))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: geometry.size.width * 0.85)
                            .position(x: geometry.size.width / 2,
                                      y: geometry.size.height / 2 + 68 * scale)
                    }
                }
                .foregroundStyle(.white.opacity(0.75))
            }
        }
        .clipped()
    }

    private func clock(_ date: Date, scale: CGFloat) -> some View {
        let formatted = DashboardFormatting.clock(date, format: store.settings.clockFormat)
        return HStack(alignment: .firstTextBaseline, spacing: 6 * scale) {
            Text(formatted.time).font(DashboardFont.numeric(size: 46 * scale))
            if let period = formatted.period {
                Text(period).font(DashboardFont.date(size: 14 * scale))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("時刻")
    }

    private func metric(symbol: String, title: String, value: String, unit: String,
                        scale: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 5 * scale) {
            Image(systemName: symbol)
                .font(.system(size: 23 * scale, weight: .regular))
                .foregroundStyle(.white.opacity(0.4))
                .accessibilityHidden(true)
            HStack(alignment: .firstTextBaseline, spacing: 1 * scale) {
                Text(value).font(DashboardFont.numeric(size: 46 * scale))
                Text(unit).font(DashboardFont.numeric(size: 32 * scale))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value == "—" ? "未取得" : "\(value) \(unit)")
    }

    private var status: some View {
        VStack(spacing: 4) {
            if store.settings.demo {
                Text("サンプルデータ")
            } else if store.stale {
                Text("更新停止")
            }
            if !store.settings.demo && !store.message.isEmpty { Text(store.message) }
        }
    }
}

/// OSにあるDINを使用する。フォントは配布物に同梱しない。
@MainActor
private enum DashboardFont {
    static let numericName = ["DINAlternate-Bold", "DINCondensed-Bold"].first { NSFont(name: $0, size: 46) != nil }
    static let dateName = ["DINAlternate-Bold", "DINCondensed-Bold"].first { NSFont(name: $0, size: 18) != nil }

    static func numeric(size: CGFloat) -> Font {
        numericName.map { Font.custom($0, fixedSize: size) } ?? .system(size: size, weight: .semibold, design: .rounded)
    }

    static func date(size: CGFloat) -> Font {
        dateName.map { Font.custom($0, fixedSize: size) } ?? .system(size: size, weight: .semibold)
    }
}
