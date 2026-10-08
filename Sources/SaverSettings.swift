import Foundation
import ScreenSaver
import Security

enum ClockFormat: String, CaseIterable, Identifiable {
    case twentyFourHour, twelveHour
    var id: String { rawValue }
    var title: String { self == .twentyFourHour ? "24時間" : "12時間" }
}

struct SaverSettings: Equatable {
    var demo = true
    var deviceID = ""
    var deviceName = ""
    var showClock = true
    var showTemperature = true
    var showHumidity = true
    var showDate = true
    var clockFormat: ClockFormat = .twentyFourHour

    var showsMeasurements: Bool { showTemperature || showHumidity }
    var showsMainRow: Bool { showClock || showsMeasurements }
}

final class SettingsRepository {
    static let identifier = "dev.psephopaiktes.SwitchBotScreenSaver"
    static let changedNotification = Notification.Name(identifier + ".settingsChanged")
    private let defaults: UserDefaults

    init(defaults: UserDefaults = ScreenSaverDefaults(forModuleWithName: identifier)!) {
        self.defaults = defaults
    }

    func load() -> SaverSettings {
        SaverSettings(
            demo: defaults.object(forKey: "demo") == nil ? true : defaults.bool(forKey: "demo"),
            deviceID: defaults.string(forKey: "deviceID") ?? "",
            deviceName: defaults.string(forKey: "deviceName") ?? "",
            showClock: enabled("showClock"),
            showTemperature: enabled("showTemperature"),
            showHumidity: enabled("showHumidity"),
            showDate: enabled("showDate"),
            clockFormat: ClockFormat(rawValue: defaults.string(forKey: "clockFormat") ?? "") ?? .twentyFourHour
        )
    }

    private func enabled(_ key: String) -> Bool {
        defaults.object(forKey: key) == nil ? true : defaults.bool(forKey: key)
    }

    func synchronize() { defaults.synchronize() }

    var revision: String { defaults.string(forKey: "revision") ?? "" }

    func save(_ settings: SaverSettings) {
        defaults.removeObject(forKey: "style")
        defaults.set(settings.demo, forKey: "demo")
        defaults.set(settings.deviceID, forKey: "deviceID")
        defaults.set(settings.deviceName, forKey: "deviceName")
        defaults.set(settings.showClock, forKey: "showClock")
        defaults.set(settings.showTemperature, forKey: "showTemperature")
        defaults.set(settings.showHumidity, forKey: "showHumidity")
        defaults.set(settings.showDate, forKey: "showDate")
        defaults.set(settings.clockFormat.rawValue, forKey: "clockFormat")
        // 同じ機器のまま認証情報だけ変更した場合も表示側を更新する。
        defaults.set(UUID().uuidString, forKey: "revision")
        defaults.synchronize()
        // 通知に認証情報・機器情報を含めない。
        DistributedNotificationCenter.default().postNotificationName(
            Self.changedNotification, object: nil, userInfo: nil, deliverImmediately: true
        )
    }
}

protocol CredentialsStoring {
    func load(interactive: Bool) throws -> SwitchBotCredentials?
    func save(_ credentials: SwitchBotCredentials) throws
    func delete() throws
}

enum CredentialsError: Error, LocalizedError {
    case unavailable, corrupt
    var errorDescription: String? {
        "Keychainにアクセスできません。スクリーンセーバーのオプションで認証情報を設定し直してください。"
    }
}

struct KeychainCredentials: CredentialsStoring {
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: SettingsRepository.identifier,
         kSecAttrAccount as String: "switchbot-api-v1.1"]
    }

    func load(interactive: Bool) throws -> SwitchBotCredentials? {
        var query = query
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        if !interactive { query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail }
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw CredentialsError.unavailable }
        guard let data = result as? Data,
              let credentials = try? JSONDecoder().decode(SwitchBotCredentials.self, from: data) else {
            throw CredentialsError.corrupt
        }
        return credentials
    }

    func save(_ credentials: SwitchBotCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
                throw CredentialsError.unavailable
            }
        } else if status != errSecSuccess { throw CredentialsError.unavailable }
    }

    func delete() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialsError.unavailable
        }
    }
}
