import Foundation

struct Host: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var domain: String
    var address: String
    var createdAt: Date = Date()
}
