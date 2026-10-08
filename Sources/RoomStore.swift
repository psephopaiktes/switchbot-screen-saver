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

    init(repository: SettingsRepository = SettingsRepository(),
         credentials: CredentialsStoring = KeychainCredentials(),
         client: SwitchBotServing = SwitchBotClient(), interval: UInt64 = 300_000_000_000) {
        self.repository = repository
        self.credentials = credentials
        self.client = client
        self.interval = interval
        settings = repository.load()
        reading = settings.demo ? .sample : nil
        message = settings.demo ? "サンプルデータ" : "設定から機器を選択してください"
    }

    func activate(_ owner: UUID) {
        owners.insert(owner)
        if task == nil { begin() }
    }

    func deactivate(_ owner: UUID) {
        owners.remove(owner)
        if owners.isEmpty { cancel() }
    }

    func reload() {
        cancel()
        settings = repository.load()
        reading = settings.demo ? .sample : nil
        updatedAt = nil
        stale = false
        message = settings.demo ? "サンプルデータ" : "接続中…"
        if !owners.isEmpty { begin() }
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
