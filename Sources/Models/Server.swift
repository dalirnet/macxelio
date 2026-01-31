import Foundation

struct Server: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var address: String
    var port: Int
    var protocolType: ProtocolType
    var isActive: Bool = false
    var createdAt: Date = Date()
    
    enum ProtocolType: String, Codable, CaseIterable {
        case vless = "VLESS"
        case vmess = "VMess"
        case trojan = "Trojan"
        case shadowsocks = "Shadowsocks"
    }
}

extension Server {
    static var example: Server {
        Server(
            name: "Example Server",
            address: "example.com",
            port: 443,
            protocolType: .vless
        )
    }
}
