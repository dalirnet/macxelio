import SwiftUI

struct HelpView: View {
    @ObservedObject var xrayCore: XrayCore
    var onBack: () -> Void

    @State private var xrayVersion = "—"

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Help") { onBack() }
            },
            headerRight: {
                HeaderButton(icon: "arrow.up.right.square", help: "GitHub") {
                    if let url = URL(string: "https://github.com/dalirnet/macxelio") {
                        NSWorkspace.shared.open(url)
                    }
                }
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            FlameIconView(isActive: true, size: 32)
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Macxelio")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Native menu bar proxy client")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }

                        Text(
                            "Switch proxies, route traffic your way, and control the system proxy and DNS — all from the menu bar. Lean and efficient: it does its job and stays out of the way."
                        )
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                        FormSection("Mode")
                        card {
                            LegendRow(
                                icon: "circle.fill", color: .primary, title: "Global",
                                detail: "Send everything through the proxy")
                            Divider()
                            LegendRow(
                                icon: "circle.lefthalf.filled", color: .primary, title: "Rule",
                                detail: "Route only what matches your rules")
                            Divider()
                            LegendRow(
                                icon: "circle", color: .primary, title: "Direct",
                                detail: "Skip the proxy entirely")
                        }

                        FormSection("System")
                        card {
                            LegendRow(
                                icon: "network", color: .primary, title: "System Proxy",
                                detail: "Route every app through Macxelio")
                            Divider()
                            LegendRow(
                                icon: "server.rack", color: .primary, title: "System DNS",
                                detail: "Apply your DNS servers system-wide")
                        }

                        FormSection("Status")
                        card {
                            LegendRow(
                                icon: "icloud.fill", color: .green, title: "Connected",
                                detail: "Latency under 0.5s")
                            Divider()
                            LegendRow(
                                icon: "icloud.fill", color: .yellow, title: "Slow",
                                detail: "Latency over 0.5s")
                            Divider()
                            LegendRow(
                                icon: "icloud.fill", color: .red, title: "Error",
                                detail: "Proxy is unreachable")
                            Divider()
                            LegendRow(
                                icon: "icloud.fill", color: .secondary, title: "Idle",
                                detail: "No Proxy")
                        }

                        FormSection("About")
                        card {
                            InfoRow(label: "Xray Core", value: xrayVersion)
                            Divider()
                            InfoRow(label: "App Version", value: appVersion)
                        }
                    }
                    .padding(16)
                }
            }
        )
        .onAppear {
            xrayVersion = xrayCore.getVersion() ?? "Not installed"
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

struct LegendRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 18, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }
}
