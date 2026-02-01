import SwiftUI

struct ConnectionsView: View {
    var onBack: () -> Void

    @StateObject private var tracker = ConnectionTracker()

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Connections") { onBack() }
            },
            headerRight: { EmptyView() },
            content: {
                if tracker.connections.isEmpty {
                    EmptyState("No active connections", icon: "network")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(tracker.connections) { connection in
                                ConnectionRow(connection: connection)
                                Divider()
                            }
                        }
                    }
                }
            },
            footerLeft: {
                HStack(spacing: 8) {
                    Text("\(tracker.totalConnections)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text("↑\(tracker.formattedUploadSpeed)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text("↓\(tracker.formattedDownloadSpeed)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            },
            footerRight: {
                Button("Clear") { tracker.clear() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(tracker.connections.isEmpty)
            }
        )
        .onAppear { tracker.start() }
        .onDisappear { tracker.stop() }
    }
}

struct ConnectionRow: View {
    let connection: ConnectionTracker.Connection

    var body: some View {
        HStack(spacing: 8) {
            SelectionIndicatorSmall(isSelected: connection.isActive, activeColor: .green)

            Text("\(connection.host):\(connection.port)")
                .font(.system(size: 11, design: .monospaced))
                .lineLimit(1)

            Spacer()

            Badge(connection.action)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}
