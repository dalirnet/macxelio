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

        var prefix: String? {
            switch self {
            case .geoip: return "geoip:"
            case .geosite: return "geosite:"
            case .domain, .ip: return nil
            }
        }
    }

    enum RuleAction: String, Codable, CaseIterable {
        case proxy = "Proxy"
        case direct = "Direct"
        case block = "Block"
    }

    var barePattern: String {
        guard let prefix = type.prefix, pattern.hasPrefix(prefix) else { return pattern }
        return String(pattern.dropFirst(prefix.count))
    }

    var routingPattern: String {
        guard let prefix = type.prefix else { return pattern }
        return pattern.hasPrefix(prefix) ? pattern : prefix + pattern
    }
}
