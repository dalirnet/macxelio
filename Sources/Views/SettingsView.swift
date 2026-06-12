import SwiftUI

struct SettingsView: View {
    @ObservedObject var appConfig: AppConfig
    var onBack: () -> Void

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Settings") { onBack() }
            },
            headerRight: {
                HeaderButton(icon: "folder", help: "Open Config Folder", action: openFolder)
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        FormSection("Proxy Server", first: true)

                        FormFieldRow(label: "Test Server") {
                            Menu {
                                ForEach(TestServer.allCases, id: \.self) { server in
                                    Button(server.name) { appConfig.testServer = server.rawValue }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(TestServer(rawValue: appConfig.testServer)?.name ?? "")
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 9))
                                }
                                .foregroundColor(.secondary)
                            }
                            .menuStyle(.button)
                            .buttonStyle(.plain)
                            .menuIndicator(.hidden)
                            .fixedSize()
                        }

                        FormFieldRow(label: "Allow LAN") {
                            Toggle("", isOn: $appConfig.allowLAN)
                                .labelsHidden()
                        }

                        FormSection("DNS Server")

                        FormField(label: "Primary DNS", icon: "globe") {
                            TextField("8.8.8.8", text: $appConfig.primaryDNS)
                                .cardTextField()
                        }

                        FormField(label: "Secondary DNS", icon: "globe") {
                            TextField("1.1.1.1", text: $appConfig.secondaryDNS)
                                .cardTextField()
                        }
                    }
                    .padding(16)
                }
            }
        )
    }

    private func openFolder() {
        NSWorkspace.shared.open(Tools.dir)
    }
}
