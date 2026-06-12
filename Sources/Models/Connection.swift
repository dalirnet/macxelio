import SwiftUI

struct Connection: Identifiable {
    let id = UUID()
    let host: String
    let inbound: String
    let route: String

    var routeColor: Color {
        switch route {
        case "direct": return .green
        case "blocked", "block": return .red
        default: return .accentColor
        }
    }
}
