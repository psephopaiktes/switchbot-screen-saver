import AppKit
import XCTest
@testable import SwitchBotSaverPreview

final class ScreenSaverTests: XCTestCase {
    func testSampleReadingIsFixedConnectionCheckData() {
        XCTAssertEqual(RoomReading.sample.temperatureCelsius, 25.9, accuracy: 0.001)
        XCTAssertEqual(RoomReading.sample.relativeHumidity, 49)
    }

    func testClockAcceptsAnExplicitTime() async {
        await MainActor.run {
            let initial = Date(timeIntervalSince1970: 0)
            let next = Date(timeIntervalSince1970: 1)
            let clock = SaverClock(now: initial)
            XCTAssertEqual(clock.now, initial)
            clock.refresh(at: next)
            XCTAssertEqual(clock.now, next)
        }
    }

    func testHostLifecycleAndResizingInBothModes() async throws {
        try await MainActor.run {
            for preview in [false, true] {
                let view = try XCTUnwrap(SwitchBotScreenSaverView(
                    frame: NSRect(x: 0, y: 0, width: 800, height: 500),
                    isPreview: preview
                ))
                XCTAssertEqual(view.isPreview, preview)
                XCTAssertEqual(view.animationTimeInterval, 1)
                XCTAssertEqual(view.subviews.count, 1)

                let initial = Date(timeIntervalSince1970: 0)
                view.clock.refresh(at: initial)
                view.animateOneFrame()
                XCTAssertEqual(view.clock.now, initial, "停止中は更新しない")

                view.startAnimation()
                XCTAssertTrue(view.isAnimating)
                XCTAssertGreaterThan(view.clock.now, initial)
                view.clock.refresh(at: initial)
                view.animateOneFrame()
                XCTAssertGreaterThan(view.clock.now, initial)

                view.stopAnimation()
                XCTAssertFalse(view.isAnimating)
                let stopped = view.clock.now
                view.animateOneFrame()
                XCTAssertEqual(view.clock.now, stopped)
                view.startAnimation()
                XCTAssertTrue(view.isAnimating)
                view.stopAnimation()

                view.setFrameSize(NSSize(width: 320, height: 200))
                XCTAssertEqual(view.subviews.first?.frame, view.bounds)
            }
        }
    }
}
