import SwiftUI

@main
struct SwitchBotSaverPreviewApp: App {
    @State private var running = true
    @State private var smallPreview = false
    @State private var settingsRequest = 0

    var body: some Scene {
        WindowGroup("SwitchBot Screen Saver") {
            VStack(spacing: 0) {
                HStack {
                    Toggle("更新を実行", isOn: $running)
                    Toggle("小さいプレビュー", isOn: $smallPreview)
                    Spacer()
                    Button("設定…") { settingsRequest += 1 }
                }
                .padding()

                NativeSaverPreview(running: running, isPreview: smallPreview, settingsRequest: settingsRequest)
                    .id(smallPreview)
                    .frame(
                        width: smallPreview ? 320 : nil,
                        height: smallPreview ? 200 : nil
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)
            }
            .frame(minWidth: 640, minHeight: 420)
        }
    }
}

/// プレビューアプリでも実際のScreenSaverViewを生成して起動・停止する。
struct NativeSaverPreview: NSViewRepresentable {
    let running: Bool
    let isPreview: Bool
    let settingsRequest: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> SwitchBotScreenSaverView {
        // 実装は常にsuper.initの結果を返す。このサイズでの生成失敗は異常。
        SwitchBotScreenSaverView(
            frame: NSRect(x: 0, y: 0, width: 800, height: 500),
            isPreview: isPreview
        )!
    }

    func updateNSView(_ view: SwitchBotScreenSaverView, context: Context) {
        if context.coordinator.lastSettingsRequest != settingsRequest {
            context.coordinator.lastSettingsRequest = settingsRequest
            if let parent = view.window, parent.attachedSheet == nil, let sheet = view.configureSheet {
                parent.beginSheet(sheet)
            }
        }
        if running {
            view.startAnimation()
        } else {
            view.stopAnimation()
        }
    }

    static func dismantleNSView(_ view: SwitchBotScreenSaverView, coordinator: Coordinator) {
        view.stopAnimation()
    }

    @MainActor
    final class Coordinator {
        var lastSettingsRequest = 0
    }
}
