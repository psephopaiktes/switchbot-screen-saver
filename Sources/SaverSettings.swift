import Foundation
import ScreenSaver
import Security

enum DisplayStyle: String, CaseIterable, Identifiable {
    case plain, liquidGlass
    var id: String { rawValue }
    var title: String { self == .plain ? "ミニマル" : "Liquid Glass" }

    static var glassAvailable: Bool {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) { return true }
        #endif
        return false
    }
}

struct SaverSettings: Equatable {
    var style: DisplayStyle = .plain
    var demo = true
    var deviceID = ""
    var deviceName = ""
}

final class SettingsRepository {
    static let identifier = "dev.psephopaiktes.SwitchBotScreenSaver"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = ScreenSaverDefaults(forModuleWithName: identifier)!) {
        self.defaults = defaults
    }

    func load() -> SaverSettings {
        SaverSettings(
            style: DisplayStyle(rawValue: defaults.string(forKey: "style") ?? "") ?? .plain,
            demo: defaults.object(forKey: "demo") == nil ? true : defaults.bool(forKey: "demo"),
            deviceID: defaults.string(forKey: "deviceID") ?? "",
            deviceName: defaults.string(forKey: "deviceName") ?? ""
        )
    }

    func save(_ settings: SaverSettings) {
        defaults.set(settings.style.rawValue, forKey: "style")
        defaults.set(settings.demo, forKey: "demo")
        defaults.set(settings.deviceID, forKey: "deviceID")
        defaults.set(settings.deviceName, forKey: "deviceName")
        defaults.synchronize()
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
