import Foundation

struct DNSServer: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var address: String
    var createdAt: Date = Date()
}

extension DNSServer {
    static var example: DNSServer {
        DNSServer(address: "8.8.8.8")
    }
}
