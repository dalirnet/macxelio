import SwiftUI

struct ConnectionsView: View {
    var onBack: () -> Void

    @StateObject private var tracker = ConnectionTracker()

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Connections") { onBack() }
            },
            headerRight: {
                HStack(spacing: 10) {
                    trafficLabel(icon: "arrow.down", value: tracker.totalDownload)
                    trafficLabel(icon: "arrow.up", value: tracker.totalUpload)
                }
            },
            content: {
                if tracker.connections.isEmpty {
                    EmptyState("No connections yet", icon: "network")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(tracker.connections) { connection in
                                ConnectionRow(connection: connection)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        )
        .onAppear { tracker.start() }
        .onDisappear { tracker.stop() }
    }

    private func trafficLabel(icon: String, value: Int64) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.primary)
            Text(formatBytes(value))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unit = 0
        while value >= 1024 && unit < units.count - 1 {
            value /= 1024
            unit += 1
        }
        return unit == 0
            ? "\(Int(value)) \(units[unit])"
            : String(format: "%.1f %@", value, units[unit])
    }
}

private struct ConnectionRow: View {
    let connection: Connection

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(connection.host)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(connection.inbound)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(connection.route.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(connection.routeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(connection.routeColor.opacity(0.15))
                .cornerRadius(5)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
}
