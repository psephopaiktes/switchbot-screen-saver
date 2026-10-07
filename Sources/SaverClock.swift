import Combine
import Foundation

/// 更新のタイミングはScreenSaverホストが管理する。独自タイマーは持たない。
@MainActor
final class SaverClock: ObservableObject {
    @Published private(set) var now: Date

    init(now: Date = Date()) {
        self.now = now
    }

    func refresh(at date: Date = Date()) {
        now = date
    }
}
