import SwiftUI

struct ClockAndRoomView: View {
    @ObservedObject var clock: SaverClock
    let reading: RoomReading

    var body: some View {
        GeometryReader { geometry in
            // 設定画面の小さなプレビューと全画面で同じ構成を使う。
            let scale = max(0.1, min(geometry.size.width / 800, geometry.size.height / 500))

            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.10, blue: 0.18), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 28 * scale) {
                    Text(clock.now, format: .dateTime.hour().minute().second())
                        .font(.system(size: 96 * scale, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .accessibilityLabel("現在時刻")

                    HStack(spacing: 64 * scale) {
                        measurement(
                            title: "室温",
                            value: String(format: "%.1f℃", reading.temperatureCelsius),
                            scale: scale
                        )
                        measurement(
                            title: "湿度",
                            value: "\(reading.relativeHumidity)%",
                            scale: scale
                        )
                    }

                    Text("サンプルデータ · Hub 2接続確認時の値")
                        .font(.system(size: 16 * scale))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(24 * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(.white)
            }
        }
        .clipped()
    }

    private func measurement(title: String, value: String, scale: CGFloat) -> some View {
        VStack(spacing: 8 * scale) {
            Text(title)
                .font(.system(size: 18 * scale))
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.system(size: 42 * scale, weight: .medium, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .accessibilityElement(children: .combine)
    }
}
