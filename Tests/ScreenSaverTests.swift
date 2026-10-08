import AppKit
import XCTest
@testable import SwitchBotSaverPreview

final class ScreenSaverTests: XCTestCase {
    // テスト専用の架空の認証情報。実際のToken・Secretは使わない。
    private let fixture = SwitchBotCredentials(token: "fixture-token", secret: "fixture-secret")

    func testSignatureMatchesIndependentHMACVector() {
        let request = SwitchBotClient.request(path: ["devices"], credentials: fixture,
                                             timestamp: 1_700_000_000_000, nonce: "fixture-nonce")
        XCTAssertEqual(request.url?.absoluteString, "https://api.switch-bot.com/v1.1/devices")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), fixture.token)
        XCTAssertEqual(request.value(forHTTPHeaderField: "t"), "1700000000000")
        XCTAssertEqual(request.value(forHTTPHeaderField: "nonce"), "fixture-nonce")
        XCTAssertEqual(request.value(forHTTPHeaderField: "sign"), "4F/DbKfNkAooNu/U6/mQuAKflt5UUGYtKz+kvZgl6yg=")
    }

    func testDeviceListSelectsTemperatureAndHumidityDevices() async throws {
        let client = responseClient(#"{"statusCode":100,"body":{"deviceList":[{"deviceId":"fixture-hub","deviceName":"テストHub","deviceType":"Hub 2"},{"deviceId":"fixture-bot","deviceName":"テストBot","deviceType":"Bot"}]}}"#)
        let devices = try await client.devices(credentials: fixture)
        XCTAssertEqual(devices.map(\.id), ["fixture-hub"])
    }

    func testReadingKeepsMissingValuesAndAcceptsZero() async throws {
        let partial = responseClient(#"{"statusCode":100,"body":{"temperature":0}}"#)
        let value = try await partial.reading(deviceID: "fixture-hub", credentials: fixture)
        XCTAssertEqual(value.temperatureCelsius, 0)
        XCTAssertNil(value.relativeHumidity)
        let complete = responseClient(#"{"statusCode":100,"body":{"temperature":25.9,"humidity":49}}"#)
        let both = try await complete.reading(deviceID: "fixture-hub", credentials: fixture)
        XCTAssertEqual(both, RoomReading.sample)
    }

    func testHTTPAndAPIErrorEnvelopesAreHandledSeparately() async {
        let cases: [(Int, String, SwitchBotError)] = [
            (401, "", .authentication), (429, "", .rateLimited), (503, "", .http(503)),
            (200, #"{"statusCode":190,"body":null,"message":"private fixture message"}"#, .api(190)),
            (200, "not JSON", .invalidResponse),
            (200, #"{"statusCode":100,"body":{}}"#, .missingMeasurements),
            (200, #"{"statusCode":100,"body":{"humidity":101}}"#, .invalidResponse)
        ]
        for (status, body, expected) in cases {
            do {
                _ = try await responseClient(body, status: status).reading(deviceID: "fixture-hub", credentials: fixture)
                XCTFail("エラー応答が成功扱いになった")
            } catch { XCTAssertEqual(error as? SwitchBotError, expected) }
        }
    }

    func testNetworkErrorsAreRedactedAndCancellationIsPreserved() async {
        let failing = SwitchBotClient { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await failing.devices(credentials: fixture)
            XCTFail("ネットワークエラーが成功扱いになった")
        } catch { XCTAssertEqual(error as? SwitchBotError, .network) }
        let cancelled = SwitchBotClient { _ in throw URLError(.cancelled) }
        do {
            _ = try await cancelled.devices(credentials: fixture)
            XCTFail("キャンセルが成功扱いになった")
        } catch { XCTAssertTrue(error is CancellationError) }
    }

    @MainActor
    func testSharedPollingRetainsLastReadingOnFailureAndStopsWithLastOwner() async throws {
        let (repository, _) = repository()
        repository.save(SaverSettings(demo: false, deviceID: "fixture-hub"))
        let client = SequenceClient()
        let store = RoomStore(repository: repository, credentials: MemoryCredentials(fixture),
                              client: client, interval: 30_000_000)
        let first = UUID(), second = UUID()
        defer { store.deactivate(first); store.deactivate(second) }
        store.activate(first)
        store.activate(second)
        try await waitUntil { store.updatedAt != nil }
        XCTAssertEqual(store.reading, .sample)
        store.deactivate(first)
        try await waitUntil { store.stale }
        XCTAssertEqual(store.reading, .sample)
        XCTAssertNotNil(store.updatedAt)
        store.deactivate(second)
        let calls = await client.calls
        try await Task.sleep(nanoseconds: 90_000_000)
        let afterStop = await client.calls
        XCTAssertEqual(afterStop, calls)
    }

    @MainActor
    func testSettingsSaveRequiresSuccessfulStatusAndDoesNotPersistSecretsInDefaults() async throws {
        let (repository, defaults) = repository()
        let credentials = MemoryCredentials(nil)
        let failed = SettingsModel(repository: repository, credentials: credentials,
                                   client: SequenceClient(alwaysFail: true), onSave: {})
        failed.settings = SaverSettings(demo: false, deviceID: "fixture-hub")
        failed.token = fixture.token; failed.secret = fixture.secret
        failed.save { XCTFail("失敗時に設定を保存した") }
        try await waitUntil { !failed.busy }
        XCTAssertNil(credentials.saved)
        XCTAssertTrue(repository.load().demo)

        let saved = expectation(description: "設定を保存")
        let model = SettingsModel(repository: repository, credentials: credentials,
                                  client: SequenceClient(), onSave: {})
        model.settings = SaverSettings(demo: false, deviceID: "fixture-hub")
        model.token = fixture.token; model.secret = fixture.secret
        model.save { saved.fulfill() }
        await fulfillment(of: [saved], timeout: 2)
        XCTAssertEqual(credentials.saved?.token, fixture.token)
        XCTAssertFalse(repository.load().demo)
        XCTAssertNil(defaults.object(forKey: "token"))
        XCTAssertNil(defaults.object(forKey: "secret"))
        XCTAssertTrue(model.token.isEmpty)
        XCTAssertTrue(model.secret.isEmpty)
    }

    @MainActor
    func testHostProvidesSettingsAndResizesInBothModes() async throws {
        for preview in [false, true] {
            let view = try XCTUnwrap(SwitchBotScreenSaverView(
                frame: NSRect(x: 0, y: 0, width: 800, height: 500), isPreview: preview))
            XCTAssertTrue(view.hasConfigureSheet)
            let sheet = try XCTUnwrap(view.configureSheet)
            XCTAssertTrue(sheet === view.configureSheet, "参照ごとに別のシートを作らない")
            XCTAssertNotNil(sheet.contentViewController)
            XCTAssertGreaterThan(sheet.contentLayoutRect.height, 400)
            XCTAssertEqual(view.subviews.count, 1)
            view.startAnimation()
            XCTAssertTrue(view.isAnimating)
            view.stopAnimation()
            XCTAssertFalse(view.isAnimating)
            view.setFrameSize(NSSize(width: 320, height: 200))
            XCTAssertEqual(view.subviews.first?.frame, view.bounds)
        }
    }

    @MainActor
    func testSettingsSheetCanPresentDismissAndReopen() async throws {
        let (repository, _) = repository()
        let model = SettingsModel(repository: repository, credentials: MemoryCredentials(nil),
                                  client: SequenceClient(), onSave: {})
        let controller = SettingsSheetController(model: model)
        let sheet = try XCTUnwrap(controller.window)
        let parent = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 700),
                              styleMask: [.titled], backing: .buffered, defer: false)
        parent.isReleasedWhenClosed = false
        parent.orderFront(nil)
        defer { controller.dismiss(); parent.close() }
        for _ in 0..<2 {
            controller.present(on: parent)
            try await waitUntil { sheet.sheetParent === parent && sheet.isVisible }
            XCTAssertTrue(parent.attachedSheet === sheet)
            XCTAssertNotNil(sheet.contentViewController?.view)
            controller.dismiss()
            try await waitUntil { parent.attachedSheet == nil && !sheet.isVisible }
            XCTAssertTrue(controller.window === sheet)
        }
    }

    private func responseClient(_ json: String, status: Int = 200) -> SwitchBotClient {
        SwitchBotClient { request in
            (Data(json.utf8), HTTPURLResponse(url: request.url!, statusCode: status,
                                            httpVersion: nil, headerFields: nil)!)
        }
    }

    @MainActor
    private func repository() -> (SettingsRepository, UserDefaults) {
        let name = "saver-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { UserDefaults.standard.removePersistentDomain(forName: name) }
        return (SettingsRepository(defaults: defaults), defaults)
    }

    @MainActor
    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(2)
        while !condition() && Date() < deadline { try await Task.sleep(nanoseconds: 5_000_000) }
        XCTAssertTrue(condition(), "状態変化がタイムアウトした")
    }
}

private final class MemoryCredentials: CredentialsStoring {
    var saved: SwitchBotCredentials?
    init(_ saved: SwitchBotCredentials?) { self.saved = saved }
    func load(interactive: Bool) throws -> SwitchBotCredentials? { saved }
    func save(_ credentials: SwitchBotCredentials) throws { saved = credentials }
    func delete() throws { saved = nil }
}

private actor SequenceClient: SwitchBotServing {
    private(set) var calls = 0
    let alwaysFail: Bool
    init(alwaysFail: Bool = false) { self.alwaysFail = alwaysFail }
    func devices(credentials: SwitchBotCredentials) async throws -> [SwitchBotDevice] { [] }
    func reading(deviceID: String, credentials: SwitchBotCredentials) async throws -> RoomReading {
        calls += 1
        if alwaysFail || calls > 1 { throw SwitchBotError.network }
        return .sample
    }
}
