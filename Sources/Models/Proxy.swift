import Foundation

struct Proxy: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var type: ProxyType
    var address: String
    var port: Int
    var uuid: String?
    var password: String?
    var method: String?
    var username: String?
    var security: Security = .none
    var sni: String?
    var fingerprint: String?
    var flow: String?
    var publicKey: String?
    var shortId: String?
    var spiderX: String?
    var createdAt: Date = Date()

    enum Security: String, Codable, CaseIterable {
        case none = "None"
        case tls = "TLS"
        case reality = "REALITY"

        var value: String { rawValue.lowercased() }
    }

    enum ProxyType: String, Codable, CaseIterable {
        case shadowsocks = "Shadowsocks"
        case vless = "VLESS"
        case vmess = "VMess"
        case trojan = "Trojan"
        case socks = "SOCKS"
        case http = "HTTP"

        var scheme: String {
            switch self {
            case .shadowsocks: return "ss"
            case .vless: return "vless"
            case .vmess: return "vmess"
            case .trojan: return "trojan"
            case .socks: return "socks"
            case .http: return "http"
            }
        }

        var supportsUDP: Bool {
            switch self {
            case .vless, .vmess, .trojan: return true
            case .shadowsocks, .socks, .http: return false
            }
        }

        var supportsSecurity: Bool {
            switch self {
            case .vless, .vmess, .trojan: return true
            case .shadowsocks, .socks, .http: return false
            }
        }

        var supportsFlow: Bool {
            self == .vless
        }
    }

    static let defaultFingerprint = "chrome"
    static let defaultMethod = "aes-256-gcm"

    static let fingerprints = [
        "chrome", "firefox", "safari", "ios", "android", "edge", "random",
    ]

    static let flows = ["", "xtls-rprx-vision"]

    static let shadowsocksMethods = [
        "aes-128-gcm", "aes-256-gcm", "chacha20-poly1305",
    ]
}
