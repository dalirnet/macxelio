import SwiftUI

struct SettingsView: View {
    @ObservedObject var appConfig: AppConfig
    var onBack: () -> Void

    @State private var httpPortText = ""
    @State private var socksPortText = ""

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Settings") {
                    commitPorts()
                    onBack()
                }
            },
            headerRight: {
                HeaderButton(icon: "folder", help: "Open Config Folder", action: openFolder)
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        FormSection("Proxy Server", first: true)

                        SelectBox(
                            TestServer.allCases.map { ($0, $0.name) },
                            selection: Binding(
                                get: { TestServer(rawValue: appConfig.testServer) ?? .google },
                                set: { appConfig.testServer = $0.rawValue }
                            ),
                            label: "Test Server"
                        )

                        FormFieldRow(label: "Allow LAN") {
                            Toggle("", isOn: $appConfig.allowLAN)
                                .labelsHidden()
                        }

                        FormFieldRow(label: "HTTP Port") {
                            TextField("\(AppConfig.defaultHTTPPort)", text: $httpPortText)
                                .rowTextField()
                                .onSubmit { commitPorts() }
                        }

                        FormFieldRow(label: "SOCKS Port") {
                            TextField("\(AppConfig.defaultSOCKSPort)", text: $socksPortText)
                                .rowTextField()
                                .onSubmit { commitPorts() }
                        }

                        FormSection("DNS Server")

                        FormFieldRow(label: "Primary DNS", error: dnsError(appConfig.primaryDNS)) {
                            TextField("https://1.1.1.1/dns-query", text: $appConfig.primaryDNS)
                                .rowTextField()
                        }

                        FormFieldRow(
                            label: "Secondary DNS", error: dnsError(appConfig.secondaryDNS)
                        ) {
                            TextField("8.8.8.8", text: $appConfig.secondaryDNS)
                                .rowTextField()
                        }
                    }
                    .padding(16)
                }
                .onAppear {
                    httpPortText = String(appConfig.httpPort)
                    socksPortText = String(appConfig.socksPort)
                }
            }
        )
    }

    private func portError(_ text: String) -> String? {
        text.isEmpty ? nil : Validator.portError(text)
    }

    private func dnsError(_ text: String) -> String? {
        text.isEmpty ? nil : Validator.dnsServerError(text)
    }

    private func commitPorts() {
        if portError(httpPortText) == nil, let port = Int(httpPortText) {
            appConfig.httpPort = port
        } else {
            httpPortText = String(appConfig.httpPort)
        }

        if portError(socksPortText) == nil, let port = Int(socksPortText) {
            appConfig.socksPort = port
        } else {
            socksPortText = String(appConfig.socksPort)
        }
    }

    private func openFolder() {
        NSWorkspace.shared.open(Tools.dir)
    }
}
