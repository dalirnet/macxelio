import Foundation

struct Rule: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var type: RuleType
    var pattern: String
    var action: RuleAction
    var createdAt: Date = Date()

    enum RuleType: String, Codable, CaseIterable {
        case domain = "Domain"
        case ip = "IP"
        case geoip = "GeoIP"
        case geosite = "GeoSite"

        var abbreviation: String {
            switch self {
            case .domain: return "DOM"
            case .ip: return "IP"
            case .geoip: return "GIP"
            case .geosite: return "GST"
            }
        }
    }

    enum RuleAction: String, Codable, CaseIterable {
        case proxy = "Proxy"
        case direct = "Direct"
        case block = "Block"

        var abbreviation: String {
            switch self {
            case .proxy: return "PRX"
            case .direct: return "DIR"
            case .block: return "BLK"
            }
        }
    }
}

extension Rule {
    static var example: Rule {
        Rule(
            type: .domain,
            pattern: "google.com",
            action: .direct
        )
    }
}
