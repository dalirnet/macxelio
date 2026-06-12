import SwiftUI

struct HostsView: View {
    @ObservedObject var appConfig: AppConfig
    var onBack: () -> Void
    var onAdd: () -> Void
    var onEdit: (Host) -> Void

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Hosts") { onBack() }
            },
            headerRight: {
                HeaderButton(icon: "plus", help: "Add Host") { onAdd() }
            },
            content: {
                if appConfig.hosts.isEmpty {
                    EmptyState("No hosts yet", icon: "doc.plaintext")
                } else {
                    StyledList(
                        appConfig.hosts,
                        onEdit: { host in onEdit(host) },
                        onDelete: { host in
                            appConfig.deleteHost(host)
                        }
                    ) { host in
                        HostRow(host: host)
                    }
                }
            }
        )
    }
}

struct HostRow: View {
    let host: Host

    var body: some View {
        StyledListRow(
            left: {
                Text(host.domain)
                    .font(.system(size: 13, design: .monospaced))
                    .lineLimit(1)
            },
            right: {
                Text(host.address)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        )
    }
}
