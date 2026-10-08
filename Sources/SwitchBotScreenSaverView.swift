import ScreenSaver
import SwiftUI
import OSLog

private enum SettingsDiagnostics {
    static let log = Logger(subsystem: "dev.psephopaiktes.SwitchBotScreenSaver", category: "settings")
}

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
        SettingsDiagnostics.log.info("Screen saver view initialized (0.2.3)")
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

    override func animateOneFrame() {
        guard isAnimating else { return }
        store.refreshSettingsIfNeeded()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil { stopAnimation() }
        super.viewWillMove(toWindow: newWindow)
    }

    override var hasConfigureSheet: Bool {
        SettingsDiagnostics.log.info("Options availability checked (0.2.3)")
        return true
    }

    override var configureSheet: NSWindow? {
        SettingsDiagnostics.log.info("configureSheet requested (0.2.3)")
        // ホストが複数回参照しても同じウィンドウを返す。
        return settingsController.window
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
        panel.contentViewController = NSHostingController(rootView: SettingsView(model: self.model) { [weak self] response in
            self?.dismiss(returnCode: response)
        })
        // Formの推奨サイズに依存せず、表示可能な領域を確保する。
        panel.setContentSize(NSSize(width: 576, height: 560))
        SettingsDiagnostics.log.info("Settings panel created")
    }

    required init?(coder: NSCoder) { nil }

    func windowDidBecomeKey(_ notification: Notification) {
        SettingsDiagnostics.log.info("Settings panel became key")
        guard needsCredentialLoad else { return }
        needsCredentialLoad = false
        // Keychainの許可UIを、設定ウィンドウが表示される前に出さない。
        model.loadCredentials()
    }

    func windowWillClose(_ notification: Notification) {
        model.cancel()
        needsCredentialLoad = true
    }

    func present(on parent: NSWindow) {
        guard let sheet = window, parent.attachedSheet == nil, sheet.sheetParent == nil else { return }
        parent.beginSheet(sheet)
        SettingsDiagnostics.log.info("Settings panel presented by app")
    }

    func dismiss(returnCode: NSApplication.ModalResponse = .cancel) {
        model.cancel()
        needsCredentialLoad = true
        guard let sheet = window else { return }
        if let parent = sheet.sheetParent {
            parent.endSheet(sheet, returnCode: returnCode)
        } else if NSApp.modalWindow === sheet {
            // LegacyホストがrunModalで表示している場合もセッションを終了する。
            NSApp.stopModal(withCode: returnCode)
        } else {
            // リモート設定ホストではsheetParentを取得できない場合がある。
            NSApp.endSheet(sheet, returnCode: returnCode.rawValue)
        }
        sheet.orderOut(nil)
        SettingsDiagnostics.log.info("Settings panel dismissed")
    }
}
