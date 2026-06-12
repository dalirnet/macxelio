import SwiftUI

struct EmptyState: View {
    let message: String
    let icon: String

    init(_ message: String, icon: String = "tray") {
        self.message = message
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.secondary)

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}
