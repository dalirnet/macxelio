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
    var createdAt: Date = Date()

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
    }
}
