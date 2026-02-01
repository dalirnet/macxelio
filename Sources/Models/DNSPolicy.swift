import Foundation

struct DNSPolicy: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var domain: String
    var dnsServer: String
    var createdAt: Date = Date()
}

extension DNSPolicy {
    static var example: DNSPolicy {
        DNSPolicy(
            domain: "geosite:ir",
            dnsServer: "178.22.122.100"
        )
    }
}
