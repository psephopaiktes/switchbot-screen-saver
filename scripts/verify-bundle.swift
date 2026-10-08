import AppKit
import ScreenSaver

@main
struct VerifyBundle {
    @MainActor
    static func main() throws {
        _ = NSApplication.shared
        guard CommandLine.arguments.count == 2,
              let bundle = Bundle(path: CommandLine.arguments[1]) else {
            throw CheckError.invalidBundle
        }
        try bundle.loadAndReturnError()
        guard let saverType = bundle.principalClass as? ScreenSaverView.Type,
              let view = saverType.init(frame: NSRect(x: 0, y: 0, width: 800, height: 500), isPreview: true),
              view.hasConfigureSheet, !view.subviews.isEmpty else {
            throw CheckError.invalidPrincipalClass
        }
        print("Bundle loader: principal class / content / settings OK")
    }

    enum CheckError: Error { case invalidBundle, invalidPrincipalClass }
}
