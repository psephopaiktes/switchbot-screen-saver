import Foundation

/// 接続確認時の値を再現する固定サンプル。現在の実測値ではない。
struct RoomReading: Equatable {
    let temperatureCelsius: Double
    let relativeHumidity: Int

    static let sample = RoomReading(temperatureCelsius: 25.9, relativeHumidity: 49)
}
