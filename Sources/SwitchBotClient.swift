import CryptoKit
import Foundation

struct SwitchBotCredentials: Codable {
    let token: String
    let secret: String
}

struct SwitchBotDevice: Decodable, Identifiable {
    let deviceId: String
    let deviceName: String
    let deviceType: String
    var id: String { deviceId }

    var supportsRoomReading: Bool {
        ["Hub 2", "Hub 3", "Meter", "MeterPlus", "WoIOSensor",
         "MeterPro", "MeterPro(CO2)", "Meter Pro", "Meter Pro (CO2 Monitor)"]
            .contains(deviceType)
    }
}

enum SwitchBotError: Error, LocalizedError, Equatable {
    case authentication, rateLimited, network, invalidResponse, missingMeasurements
    case http(Int), api(Int)

    var errorDescription: String? {
        switch self {
        case .authentication: return "認証できません。TokenとSecretを確認してください。"
        case .rateLimited: return "APIの利用上限に達しました。しばらく待ってください。"
        case .network: return "接続できません。ネットワークを確認してください。"
        case .invalidResponse: return "APIの応答を読み取れませんでした。"
        case .missingMeasurements: return "この機器から温湿度を取得できません。クラウド連携を確認してください。"
        case .http(let code): return "サーバーとの通信に失敗しました（HTTP \(code)）。"
        case .api(let code): return "機器の状態を取得できませんでした（API \(code)）。"
        }
    }
}

protocol SwitchBotServing {
    func devices(credentials: SwitchBotCredentials) async throws -> [SwitchBotDevice]
    func reading(deviceID: String, credentials: SwitchBotCredentials) async throws -> RoomReading
}

private final class NoRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

struct SwitchBotClient: SwitchBotServing {
    typealias Transport = (URLRequest) async throws -> (Data, HTTPURLResponse)
    private let transport: Transport

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.httpShouldSetCookies = false
        return URLSession(configuration: configuration, delegate: NoRedirects(), delegateQueue: nil)
    }()

    init(transport: Transport? = nil) {
        self.transport = transport ?? { request in
            let (data, response) = try await Self.session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw SwitchBotError.invalidResponse }
            return (data, http)
        }
    }

    static func request(path: [String], credentials: SwitchBotCredentials,
                        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
                        nonce: String = UUID().uuidString) -> URLRequest {
        var url = URL(string: "https://api.switch-bot.com/v1.1")!
        for component in path { url.appendPathComponent(component) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let time = String(timestamp)
        let message = Data((credentials.token + time + nonce).utf8)
        let signature = HMAC<SHA256>.authenticationCode(
            for: message, using: SymmetricKey(data: Data(credentials.secret.utf8))
        )
        request.setValue(credentials.token, forHTTPHeaderField: "Authorization")
        request.setValue(Data(signature).base64EncodedString(), forHTTPHeaderField: "sign")
        request.setValue(time, forHTTPHeaderField: "t")
        request.setValue(nonce, forHTTPHeaderField: "nonce")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    func devices(credentials: SwitchBotCredentials) async throws -> [SwitchBotDevice] {
        struct DeviceList: Decodable { let deviceList: [SwitchBotDevice] }
        let list: DeviceList = try await get(path: ["devices"], credentials: credentials)
        return list.deviceList.filter(\.supportsRoomReading)
    }

    func reading(deviceID: String, credentials: SwitchBotCredentials) async throws -> RoomReading {
        struct Status: Decodable { let temperature: Double?; let humidity: Double? }
        let status: Status = try await get(path: ["devices", deviceID, "status"], credentials: credentials)
        guard status.temperature != nil || status.humidity != nil else {
            throw SwitchBotError.missingMeasurements
        }
        guard status.temperature.map({ $0.isFinite }) ?? true,
              status.humidity.map({ $0.isFinite && (0...100).contains($0) }) ?? true else {
            throw SwitchBotError.invalidResponse
        }
        return RoomReading(temperatureCelsius: status.temperature, relativeHumidity: status.humidity)
    }

    private func get<Body: Decodable>(path: [String], credentials: SwitchBotCredentials) async throws -> Body {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport(Self.request(path: path, credentials: credentials))
        } catch is CancellationError { throw CancellationError() }
        catch let error as URLError where error.code == .cancelled { throw CancellationError() }
        catch { throw SwitchBotError.network }
        try Task.checkCancellation()
        switch response.statusCode {
        case 200..<300: break
        case 401, 403: throw SwitchBotError.authentication
        case 429: throw SwitchBotError.rateLimited
        default: throw SwitchBotError.http(response.statusCode)
        }
        // エラー本文やサーバーメッセージには個人情報が含まれ得るため表示しない。
        let decoder = JSONDecoder()
        guard let header = try? decoder.decode(APIHeader.self, from: data) else {
            throw SwitchBotError.invalidResponse
        }
        guard header.statusCode == 100 else { throw SwitchBotError.api(header.statusCode) }
        guard let envelope = try? decoder.decode(APIEnvelope<Body>.self, from: data) else {
            throw SwitchBotError.invalidResponse
        }
        return envelope.body
    }
}

private struct APIEnvelope<Body: Decodable>: Decodable { let body: Body }
private struct APIHeader: Decodable { let statusCode: Int }
