import Foundation

enum TestServer: String, CaseIterable {
    case google
    case cloudflare

    var name: String {
        switch self {
        case .google: return "Google"
        case .cloudflare: return "Cloudflare"
        }
    }

    var url: String {
        switch self {
        case .google: return "https://clients3.google.com/generate_204"
        case .cloudflare: return "https://cp.cloudflare.com/generate_204"
        }
    }
}
