import SwiftUI

struct RoomDashboardView: View {
    @ObservedObject var store: RoomStore

    var body: some View {
        GeometryReader { geometry in
            let scale = max(0.15, min(geometry.size.width / 1000, geometry.size.height / 600))
            VStack(spacing: 32 * scale) {
                HStack(spacing: 28 * scale) {
                    metric(symbol: "thermometer.medium", title: "室温",
                           value: store.reading?.temperatureCelsius.map { String(format: "%.1f", $0) } ?? "—",
                           unit: "°C", color: Color(red: 1, green: 0.62, blue: 0.38), scale: scale)
                    metric(symbol: "humidity.fill", title: "湿度",
                           value: store.reading?.relativeHumidity.map { String(format: "%.0f", $0) } ?? "—",
                           unit: "%", color: Color(red: 0.39, green: 0.75, blue: 1), scale: scale)
                }
                VStack(spacing: 8 * scale) {
                    if store.settings.demo {
                        Text("サンプルデータ")
                    } else if let updatedAt = store.updatedAt {
                        Text("\(store.stale ? "更新停止 · " : "")最終取得 \(updatedAt.formatted(date: .omitted, time: .shortened))")
                    }
                    if !store.settings.demo && !store.message.isEmpty { Text(store.message) }
                }
                .font(.system(size: 14 * scale, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            }
            .padding(32 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        }
        .clipped()
    }

    private func metric(symbol: String, title: String, value: String, unit: String,
                        color: Color, scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 24 * scale) {
            HStack(spacing: 12 * scale) {
                Image(systemName: symbol)
                    .foregroundStyle(color)
                    .font(.system(size: 26 * scale, weight: .medium))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 18 * scale, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
            HStack(alignment: .firstTextBaseline, spacing: 8 * scale) {
                Text(value)
                    .font(.system(size: 100 * scale, weight: .light, design: .rounded))
                    .monospacedDigit()
                Text(unit)
                    .font(.system(size: 30 * scale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
        .frame(width: 330 * scale, alignment: .leading)
        .padding(32 * scale)
        .foregroundStyle(.white)
        .modifier(MetricSurface(radius: 32 * scale))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value == "—" ? "未取得" : "\(value) \(unit)")
    }
}

private struct MetricSurface: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        content
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(.white.opacity(0.08), lineWidth: 1))
    }
}
