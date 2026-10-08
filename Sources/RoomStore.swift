import Combine
import Foundation

/// 同一ホストプロセスのプレビュー・複数画面で取得処理を共有する。
@MainActor
final class RoomStore: ObservableObject {
    static let shared = RoomStore()
    @Published private(set) var settings: SaverSettings
    @Published private(set) var reading: RoomReading?
    @Published private(set) var updatedAt: Date?
    @Published private(set) var message = ""
    @Published private(set) var stale = false

    private let repository: SettingsRepository
    private let credentials: CredentialsStoring
    private let client: SwitchBotServing
    private let interval: UInt64
    private var owners: Set<UUID> = []
    private var task: Task<Void, Never>?
    private var generation = UUID()
    private var observedRevision: String
    private var settingsObserver: NSObjectProtocol?
    private var lastSettingsCheck = Date.distantPast

    init(repository: SettingsRepository = SettingsRepository(),
         credentials: CredentialsStoring = KeychainCredentials(),
         client: SwitchBotServing = SwitchBotClient(), interval: UInt64 = 300_000_000_000) {
        self.repository = repository
        self.credentials = credentials
        self.client = client
        self.interval = interval
        repository.synchronize()
        observedRevision = repository.revision
        let initial = repository.load()
        settings = initial
        reading = initial.demo ? .sample : nil
        message = initial.demo ? "サンプルデータ" : "設定から機器を選択してください"
    }

    func activate(_ owner: UUID) {
        if owners.isEmpty {
            settingsObserver = DistributedNotificationCenter.default().addObserver(
                forName: SettingsRepository.changedNotification, object: nil, queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.refreshSettingsIfNeeded(force: true) }
            }
        }
        owners.insert(owner)
        refreshSettingsIfNeeded(force: true)
        if task == nil { begin() }
    }

    func deactivate(_ owner: UUID) {
        owners.remove(owner)
        if owners.isEmpty {
            cancel()
            if let settingsObserver {
                DistributedNotificationCenter.default().removeObserver(settingsObserver)
                self.settingsObserver = nil
            }
        }
    }

    func reload() {
        cancel()
        repository.synchronize()
        observedRevision = repository.revision
        settings = repository.load()
        reading = settings.demo ? .sample : nil
        updatedAt = nil
        stale = false
        message = settings.demo ? "サンプルデータ" : "接続中…"
        if !owners.isEmpty { begin() }
    }

    /// 通知が届かないホストでも、OSのフレーム通知で保存設定を確認する。
    func refreshSettingsIfNeeded(force: Bool = false) {
        guard !owners.isEmpty else { return }
        let now = Date()
        guard force || now.timeIntervalSince(lastSettingsCheck) >= 1 else { return }
        lastSettingsCheck = now
        repository.synchronize()
        if repository.revision != observedRevision || repository.load() != settings {
            reload()
        }
    }

    private func cancel() {
        generation = UUID()
        task?.cancel()
        task = nil
    }

    private func begin() {
        let currentSettings = repository.load()
        if currentSettings != settings {
            settings = currentSettings
            reading = settings.demo ? .sample : nil
            updatedAt = nil
            stale = false
        }
        guard settings.showsMeasurements else {
            reading = nil
            updatedAt = nil
            stale = false
            message = ""
            return
        }
        if settings.demo {
            reading = .sample
            updatedAt = nil
            stale = false
            message = "サンプルデータ"
            return
        }
        let credential: SwitchBotCredentials
        do {
            guard !settings.deviceID.isEmpty, let saved = try credentials.load(interactive: false) else {
                stale = reading != nil
                message = "オプションでToken・Secretと機器を設定してください"
                return
            }
            credential = saved
        } catch {
            stale = reading != nil
            message = CredentialsError.unavailable.localizedDescription
            return
        }
        let deviceID = settings.deviceID
        if reading == nil { message = "取得中…" }
        let current = generation
        task = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    let value = try await self.client.reading(deviceID: deviceID, credentials: credential)
                    try Task.checkCancellation()
                    guard self.generation == current else { return }
                    self.reading = value
                    self.updatedAt = Date()
                    self.stale = false
                    self.message = ""
                } catch is CancellationError { return }
                catch {
                    guard !Task.isCancelled, self.generation == current else { return }
                    self.stale = true
                    self.message = (error as? SwitchBotError)?.localizedDescription ?? "取得できませんでした"
                }
                do { try await Task.sleep(nanoseconds: self.interval) }
                catch { return }
            }
        }
    }
}
