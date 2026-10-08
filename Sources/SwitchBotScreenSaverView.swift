import ScreenSaver
import SwiftUI

/// Info.plistのNSPrincipalClassと一致する、ホストから生成されるクラス。
@MainActor
@objc(SwitchBotScreenSaverView)
final class SwitchBotScreenSaverView: ScreenSaverView {
    private let owner = UUID()
    private let store: RoomStore
    private var settingsWindow: NSWindow?

    override init?(frame: NSRect, isPreview: Bool) {
        store = .shared
        super.init(frame: frame, isPreview: isPreview)
        installContent()
    }

    required init?(coder: NSCoder) {
        store = .shared
        super.init(coder: coder)
        installContent()
    }

    private func installContent() {
        animationTimeInterval = 1
        let content = NSHostingView(rootView: RoomDashboardView(store: store))
        content.frame = bounds
        content.autoresizingMask = [.width, .height]
        addSubview(content)
    }

    override func startAnimation() {
        guard !isAnimating else { return }
        super.startAnimation()
        store.activate(owner)
    }

    override func stopAnimation() {
        store.deactivate(owner)
        super.stopAnimation()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil { stopAnimation() }
        super.viewWillMove(toWindow: newWindow)
    }

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        let sheet = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 576, height: 460),
                             styleMask: [.titled], backing: .buffered, defer: false)
        sheet.title = "SwitchBotの設定"
        sheet.contentView = NSHostingView(rootView: SettingsView { [weak sheet] in
            guard let sheet else { return }
            NSApp.endSheet(sheet)
            sheet.orderOut(nil)
        })
        settingsWindow = sheet
        return sheet
    }
}
