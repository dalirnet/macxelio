import SwiftUI

struct HelpView: View {
    @ObservedObject var xrayCore: XrayCore
    var onBack: () -> Void

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Help") { onBack() }
            },
            headerRight: { EmptyView() },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // About
                        Text(
                            "A simple, native macOS proxy client. No Electron, no WebView, just pure Swift and Xray-core."
                        )
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                        // Info
                        VStack(spacing: 0) {
                            InfoRow(
                                label: "Xray Core", value: xrayCore.getVersion() ?? "Not installed")
                            Divider()
                            InfoRow(label: "App Version", value: appVersion)
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)

                        // Shortcuts
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Keyboard Shortcuts")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)

                            VStack(spacing: 0) {
                                ShortcutRow(key: "⌘ ,", description: "Settings")
                                Divider()
                                ShortcutRow(key: "⌘ N", description: "Add Config")
                                Divider()
                                ShortcutRow(key: "⌘ Q", description: "Quit")
                            }
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                    .padding(12)
                }
            },
            footerLeft: { EmptyView() },
            footerRight: {
                Button("GitHub") {
                    if let url = URL(string: "https://github.com/dalirnet/macxelio") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        )
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

struct ShortcutRow: View {
    let key: String
    let description: String

    var body: some View {
        HStack {
            Text(key)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)

            Text(description)
                .font(.system(size: 12))

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}
