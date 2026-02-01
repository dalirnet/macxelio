import SwiftUI

/// Empty state placeholder
struct EmptyState: View {
    let icon: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    init(
        _ message: String, icon: String = "tray", action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.message = message
        self.icon = icon
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.secondary)

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Label(label, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .padding(.top, 4)
            }
        }
    }
}
