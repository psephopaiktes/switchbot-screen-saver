import SwiftUI

@main
struct SwitchBotSaverPreviewApp: App {
    @State private var running = true
    @State private var smallPreview = false

    var body: some Scene {
        WindowGroup("SwitchBot Screen Saver — サンプル") {
            VStack(spacing: 0) {
                HStack {
                    Toggle("時計を更新", isOn: $running)
                    Toggle("小さいプレビュー", isOn: $smallPreview)
                }
                .padding()

                NativeSaverPreview(running: running, isPreview: smallPreview)
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
        if running {
            view.startAnimation()
            context.coordinator.startFrames(for: view)
        } else {
            context.coordinator.stopFrames()
            view.stopAnimation()
        }
    }

    static func dismantleNSView(_ view: SwitchBotScreenSaverView, coordinator: Coordinator) {
        coordinator.stopFrames()
        view.stopAnimation()
    }

    @MainActor
    final class Coordinator {
        private var timer: Timer?

        // 通常アプリにはOSのスクリーンセーバーホストがいないため、
        // プレビュー側だけでホストのフレームコールバックを再現する。
        func startFrames(for view: SwitchBotScreenSaverView) {
            guard timer == nil else { return }
            let timer = Timer(timeInterval: view.animationTimeInterval, repeats: true) { [weak view] _ in
                Task { @MainActor in
                    view?.animateOneFrame()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }

        func stopFrames() {
            timer?.invalidate()
            timer = nil
        }
    }
}
