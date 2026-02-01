import Foundation

struct Config: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var type: ConfigType
    var address: String
    var port: Int
    var uuid: String?
    var password: String?
    var method: String?
    var username: String?
    var ping: Int?
    var createdAt: Date = Date()

    enum ConfigType: String, Codable, CaseIterable {
        case shadowsocks = "Shadowsocks"
        case vless = "VLESS"
        case vmess = "VMess"
        case trojan = "Trojan"
        case socks = "SOCKS"
        case http = "HTTP"

        var abbreviation: String {
            switch self {
            case .shadowsocks: return "SS"
            case .vless: return "VL"
            case .vmess: return "VM"
            case .trojan: return "TR"
            case .socks: return "SO"
            case .http: return "HT"
            }
        }
    }
}

extension Config {
    static var example: Config {
        Config(
            name: "Example Config",
            type: .vless,
            address: "example.com",
            port: 443,
            uuid: "00000000-0000-0000-0000-000000000000"
        )
    }
}
