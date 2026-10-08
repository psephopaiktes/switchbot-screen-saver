import ScreenSaver
import SwiftUI

/// Info.plistのNSPrincipalClassと一致する、ホストから生成されるクラス。
@MainActor
@objc(SwitchBotScreenSaverView)
final class SwitchBotScreenSaverView: ScreenSaverView {
    private let owner = UUID()
    private let store: RoomStore
    private lazy var settingsController = SettingsSheetController()

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
        // ホストが複数回参照しても同じウィンドウを返す。
        settingsController.window
    }

    @discardableResult
    func presentSettings() -> Bool {
        guard let parent = window, parent.attachedSheet == nil else { return false }
        settingsController.present(on: parent)
        return true
    }
}

@MainActor
final class SettingsSheetController: NSWindowController, NSWindowDelegate {
    private let model: SettingsModel
    private var needsCredentialLoad = true

    init(model: SettingsModel? = nil) {
        self.model = model ?? SettingsModel()
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 576, height: 560),
                            styleMask: [.titled], backing: .buffered, defer: false)
        panel.title = "SwitchBotの設定"
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        super.init(window: panel)
        panel.delegate = self
        panel.contentViewController = NSHostingController(rootView: SettingsView(model: self.model) { [weak self] in
            self?.dismiss()
        })
        // Formの推奨サイズに依存せず、表示可能な領域を確保する。
        panel.setContentSize(NSSize(width: 576, height: 560))
    }

    required init?(coder: NSCoder) { nil }

    func windowDidBecomeKey(_ notification: Notification) {
        guard needsCredentialLoad else { return }
        needsCredentialLoad = false
        // Keychainの許可UIを、設定ウィンドウが表示される前に出さない。
        model.loadCredentials()
    }

    func present(on parent: NSWindow) {
        guard let sheet = window, parent.attachedSheet == nil, sheet.sheetParent == nil else { return }
        parent.beginSheet(sheet)
    }

    func dismiss() {
        model.cancel()
        needsCredentialLoad = true
        guard let sheet = window else { return }
        sheet.sheetParent?.endSheet(sheet)
        sheet.orderOut(nil)
    }
}
