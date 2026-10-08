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
        for name in ["thumbnail", "thumbnail@2x"] {
            guard let url = bundle.url(forResource: name, withExtension: "png"),
                  let image = NSImage(contentsOf: url), image.isValid else {
                throw CheckError.invalidThumbnail
            }
        }
        guard let saverType = bundle.principalClass as? ScreenSaverView.Type,
              let view = saverType.init(frame: NSRect(x: 0, y: 0, width: 800, height: 500), isPreview: true),
              view.hasConfigureSheet, !view.subviews.isEmpty else {
            throw CheckError.invalidPrincipalClass
        }
        print("Bundle loader: principal class / content / settings / thumbnails OK")
    }

    enum CheckError: Error { case invalidBundle, invalidPrincipalClass, invalidThumbnail }
}
