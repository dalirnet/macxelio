import SwiftUI

struct DNSView: View {
    @ObservedObject var appConfig: AppConfig
    var onBack: () -> Void
    var onAddServer: () -> Void
    var onEditServer: (DNSServer) -> Void
    var onAddPolicy: () -> Void
    var onEditPolicy: (DNSPolicy) -> Void

    @State private var selectedTab = 0

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "DNS") { onBack() }
            },
            headerRight: {
                Button(action: {
                    if selectedTab == 0 {
                        onAddServer()
                    } else {
                        onAddPolicy()
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            },
            content: {
                if selectedTab == 0 {
                    serversList
                } else {
                    policiesList
                }
            },
            footerLeft: { EmptyView() },
            footerRight: {
                Picker("", selection: $selectedTab) {
                    Text("SRV").tag(0)
                    Text("POL").tag(1)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .fixedSize()
            }
        )
    }

    private var serversList: some View {
        Group {
            if appConfig.dnsServers.isEmpty {
                EmptyState("No DNS servers yet", icon: "globe")
            } else {
                StyledList(
                    appConfig.dnsServers,
                    onDelete: { server in
                        appConfig.deleteDNSServer(server)
                    }
                ) { server in
                    DNSServerRow(server: server, onEdit: { onEditServer(server) })
                }
            }
        }
    }

    private var policiesList: some View {
        Group {
            if appConfig.dnsPolicies.isEmpty {
                EmptyState("No DNS policies yet", icon: "arrow.triangle.branch")
            } else {
                StyledList(
                    appConfig.dnsPolicies,
                    onDelete: { policy in
                        appConfig.deleteDNSPolicy(policy)
                    }
                ) { policy in
                    DNSPolicyRow(policy: policy, onEdit: { onEditPolicy(policy) })
                }
            }
        }
    }
}

struct DNSServerRow: View {
    let server: DNSServer
    let onEdit: () -> Void

    var body: some View {
        StyledListRow(
            left: {
                Text(server.address)
                    .font(.system(size: 13, design: .monospaced))
                    .lineLimit(1)
            },
            right: {
                if server.address.hasPrefix("https://") {
                    Badge("DoH")
                }
            }
        )
        .onTapGesture {
            onEdit()
        }
    }
}

struct DNSPolicyRow: View {
    let policy: DNSPolicy
    let onEdit: () -> Void

    var body: some View {
        StyledListRow(
            left: {
                Text(policy.domain)
                    .font(.system(size: 13, design: .monospaced))
                    .lineLimit(1)
            },
            right: {
                Text(policy.dnsServer)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        )
        .onTapGesture {
            onEdit()
        }
    }
}
