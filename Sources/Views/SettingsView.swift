import SwiftUI

struct SettingsView: View {
    @ObservedObject var appConfig: AppConfig
    @ObservedObject var xrayCore: XrayCore
    var onBack: () -> Void

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Settings") { onBack() }
            },
            headerRight: {
                Button(action: openConfig) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("Open Config File")
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        FormField(label: "SOCKS Port") {
                            TextField("10808", value: $appConfig.socksPort, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }

                        FormField(label: "HTTP Port") {
                            TextField("10809", value: $appConfig.httpPort, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }

                        Divider()
                            .padding(.vertical, 4)

                        FormField(label: "Auto Connect") {
                            Toggle("", isOn: $appConfig.autoConnect)
                                .labelsHidden()
                        }

                        FormField(label: "Allow LAN") {
                            Toggle("", isOn: $appConfig.allowLAN)
                                .labelsHidden()
                        }
                    }
                    .padding(12)
                }
            },
            footerLeft: { EmptyView() },
            footerRight: { EmptyView() }
        )
    }

    private func openConfig() {
        let configPath = URL(fileURLWithPath: appConfig.getConfigPath())
        NSWorkspace.shared.open(configPath)
    }
}
