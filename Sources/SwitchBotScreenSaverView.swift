import ScreenSaver
import SwiftUI

/// Info.plistのNSPrincipalClassと一致する、ホストから生成されるクラス。
@MainActor
@objc(SwitchBotScreenSaverView)
final class SwitchBotScreenSaverView: ScreenSaverView {
    let clock = SaverClock()

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        installContent()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installContent()
    }

    private func installContent() {
        animationTimeInterval = 1
        let content = NSHostingView(rootView: ClockAndRoomView(clock: clock, reading: .sample))
        content.frame = bounds
        content.autoresizingMask = [.width, .height]
        addSubview(content)
    }

    override func startAnimation() {
        guard !isAnimating else { return }
        super.startAnimation()
        clock.refresh()
    }

    override func animateOneFrame() {
        // 停止後に遅れて届いたフレームでも時計を更新しない。
        guard isAnimating else { return }
        clock.refresh()
    }

    override func stopAnimation() {
        super.stopAnimation()
        // 独自タイマー・APIポーリングはない。停止はホストに任せる。
    }
}
