import Combine
import SwiftUI

@MainActor
final class SettingsModel: ObservableObject {
    @Published var settings: SaverSettings
    @Published var token = ""
    @Published var secret = ""
    @Published private(set) var devices: [SwitchBotDevice] = []
    @Published private(set) var busy = false
    @Published private(set) var message = ""
    private let repository: SettingsRepository
    private let credentials: CredentialsStoring
    private let client: SwitchBotServing
    private let onSave: @MainActor () -> Void
    private var task: Task<Void, Never>?

    init(repository: SettingsRepository = SettingsRepository(),
         credentials: CredentialsStoring = KeychainCredentials(),
         client: SwitchBotServing = SwitchBotClient(),
         onSave: @escaping @MainActor () -> Void = { RoomStore.shared.reload() }) {
        self.repository = repository
        self.credentials = credentials
        self.client = client
        self.onSave = onSave
        settings = repository.load()
        if !settings.deviceID.isEmpty {
            devices = [SwitchBotDevice(deviceId: settings.deviceID,
                                       deviceName: settings.deviceName, deviceType: "")]
        }
    }

    func loadCredentials() {
        do {
            if let saved = try credentials.load(interactive: true) {
                token = saved.token
                secret = saved.secret
            }
        } catch { message = CredentialsError.unavailable.localizedDescription }
    }

    private var enteredCredentials: SwitchBotCredentials {
        SwitchBotCredentials(token: token.trimmingCharacters(in: .whitespacesAndNewlines),
                             secret: secret.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var canConnect: Bool {
        !busy && !enteredCredentials.token.isEmpty && !enteredCredentials.secret.isEmpty
    }

    var canSave: Bool { !busy && (settings.demo || (canConnect && !settings.deviceID.isEmpty)) }

    func connect() {
        guard canConnect else { return }
        let entered = enteredCredentials
        busy = true
        message = "機器一覧を取得しています…"
        task = Task {
            defer { busy = false }
            do {
                let fetched = try await client.devices(credentials: entered)
                try Task.checkCancellation()
                devices = fetched
                if !fetched.contains(where: { $0.id == settings.deviceID }) {
                    settings.deviceID = fetched.first?.id ?? ""
                }
                message = fetched.isEmpty ? "温湿度に対応する機器がありません。クラウド連携を確認してください。" : "機器を選んで保存してください。"
            } catch is CancellationError { }
            catch { message = (error as? SwitchBotError)?.localizedDescription ?? "接続できませんでした" }
        }
    }

    func save(completion: @escaping () -> Void) {
        guard canSave else { return }
        var candidate = settings
        let entered = enteredCredentials
        candidate.deviceName = devices.first(where: { $0.id == candidate.deviceID })?.deviceName ?? candidate.deviceName
        busy = true
        message = "接続を確認しています…"
        task = Task {
            defer { busy = false }
            do {
                if !candidate.demo {
                    _ = try await client.reading(deviceID: candidate.deviceID, credentials: entered)
                    try Task.checkCancellation()
                    try credentials.save(entered)
                }
                try Task.checkCancellation()
                repository.save(candidate)
                onSave()
                clearSensitiveFields()
                completion()
            } catch is CancellationError { }
            catch let error as CredentialsError { message = error.localizedDescription }
            catch { message = (error as? SwitchBotError)?.localizedDescription ?? "保存できませんでした" }
        }
    }

    func forgetCredentials() {
        guard !busy else { return }
        do {
            try credentials.delete()
            clearSensitiveFields()
            settings.deviceID = ""
            settings.deviceName = ""
            settings.demo = true
            devices = []
            repository.save(settings)
            onSave()
            message = "認証情報を削除しました。"
        } catch { message = CredentialsError.unavailable.localizedDescription }
    }

    func cancel() {
        task?.cancel()
        clearSensitiveFields()
    }

    private func clearSensitiveFields() { token = ""; secret = "" }
}

struct SettingsView: View {
    @StateObject var model = SettingsModel()
    @State private var confirmDeletion = false
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("SwitchBot Screen Saver").font(.title2.weight(.semibold))
            Form {
                Picker("表示スタイル", selection: $model.settings.style) {
                    Text("ミニマル").tag(DisplayStyle.plain)
                    if DisplayStyle.glassAvailable {
                        Text("Liquid Glass").tag(DisplayStyle.liquidGlass)
                    }
                }
                if !DisplayStyle.glassAvailable {
                    Text("Liquid GlassはmacOS 26以降で利用できます。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Toggle("サンプルデータで表示", isOn: $model.settings.demo)
                if !model.settings.demo {
                    SecureField("Open Token", text: $model.token)
                    SecureField("Secret", text: $model.secret)
                    Text("認証情報はこのMacのKeychainに保存します。")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("接続して機器を取得") { model.connect() }
                        .disabled(!model.canConnect)
                    Picker("表示する機器", selection: $model.settings.deviceID) {
                        Text("選択してください").tag("")
                        ForEach(model.devices) { device in
                            Text(device.deviceName).tag(device.id)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .disabled(model.busy)

            if !model.message.isEmpty {
                Text(model.message).font(.callout).foregroundStyle(.secondary)
            }
            HStack {
                Button("認証情報を削除…", role: .destructive) { confirmDeletion = true }
                    .disabled(model.busy)
                Spacer()
                if model.busy { ProgressView().controlSize(.small) }
                Button("キャンセル") { model.cancel(); onClose() }
                    .keyboardShortcut(.cancelAction)
                Button("保存") { model.save(completion: onClose) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.canSave)
            }
        }
        .padding(28)
        .frame(width: 576, height: 560)
        .onAppear { model.loadCredentials() }
        .onDisappear { model.cancel() }
        .confirmationDialog("Keychainの認証情報を削除しますか？", isPresented: $confirmDeletion) {
            Button("削除", role: .destructive) { model.forgetCredentials() }
        }
    }
}
