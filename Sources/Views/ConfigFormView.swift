import SwiftUI

struct ConfigFormView: View {
    @ObservedObject var appConfig: AppConfig
    var editingConfig: Config?
    var onBack: () -> Void

    @State private var name = ""
    @State private var type: Config.ConfigType = .shadowsocks
    @State private var address = ""
    @State private var port = "443"
    @State private var uuid = ""
    @State private var password = ""
    @State private var method = "aes-256-gcm"
    @State private var username = ""

    private let parser = ConfigParser()

    private let shadowsocksMethods: [(value: String, abbr: String)] = [
        ("aes-128-gcm", "A128"),
        ("aes-256-gcm", "A256"),
        ("chacha20-poly1305", "CH20"),
    ]

    var isEditing: Bool { editingConfig != nil }

    var isValid: Bool {
        guard !name.isEmpty && !address.isEmpty && !port.isEmpty else { return false }

        switch type {
        case .vless, .vmess:
            return !uuid.isEmpty
        case .trojan:
            return !password.isEmpty
        case .shadowsocks:
            return !password.isEmpty && !method.isEmpty
        case .socks, .http:
            return true
        }
    }

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: isEditing ? "Edit Config" : "Add Config") { onBack() }
            },
            headerRight: {
                Button("Save") { saveConfig() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!isValid)
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        FormField(label: "Name") {
                            TextField("My Server", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        FormField(label: "Type") {
                            Picker("", selection: $type) {
                                ForEach(Config.ConfigType.allCases, id: \.self) { t in
                                    Text(t.abbreviation).tag(t)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                        }

                        FormField(label: "Address") {
                            TextField("example.com", text: $address)
                                .textFieldStyle(.roundedBorder)
                        }

                        FormField(label: "Port") {
                            TextField("443", text: $port)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Dynamic fields based on type
                        dynamicFields
                    }
                    .padding(12)
                }
            },
            footerLeft: { EmptyView() },
            footerRight: {
                if !isEditing {
                    Button("Import from Clipboard", action: pasteFromClipboard)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        )
        .onAppear {
            if let config = editingConfig {
                name = config.name
                type = config.type
                address = config.address
                port = String(config.port)
                uuid = config.uuid ?? ""
                password = config.password ?? ""
                method = config.method ?? "aes-256-gcm"
                username = config.username ?? ""
            }
        }
    }

    @ViewBuilder
    private var dynamicFields: some View {
        switch type {
        case .vless, .vmess:
            FormField(label: "UUID") {
                TextField("00000000-0000-0000-0000-000000000000", text: $uuid)
                    .textFieldStyle(.roundedBorder)
            }

        case .trojan:
            FormField(label: "Password") {
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }

        case .shadowsocks:
            FormField(label: "Password") {
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }

            FormField(label: "Method") {
                Picker("", selection: $method) {
                    ForEach(shadowsocksMethods, id: \.value) { m in
                        Text(m.abbr).tag(m.value)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

        case .socks, .http:
            FormField(label: "Username (Optional)") {
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
            }

            FormField(label: "Password (Optional)") {
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func saveConfig() {
        let config = Config(
            id: editingConfig?.id ?? UUID(),
            name: name,
            type: type,
            address: address,
            port: Int(port) ?? 443,
            uuid: uuid.isEmpty ? nil : uuid,
            password: password.isEmpty ? nil : password,
            method: method.isEmpty ? nil : method,
            username: username.isEmpty ? nil : username,
            ping: editingConfig?.ping,
            createdAt: editingConfig?.createdAt ?? Date()
        )

        if isEditing {
            appConfig.updateConfig(config)
        } else {
            appConfig.addConfig(config)
        }

        onBack()
    }

    private func pasteFromClipboard() {
        guard let content = NSPasteboard.general.string(forType: .string) else { return }

        if let config = parser.parse(uri: content) {
            name = config.name
            type = config.type
            address = config.address
            port = String(config.port)
            uuid = config.uuid ?? ""
            password = config.password ?? ""
            method = config.method ?? "aes-256-gcm"
            username = config.username ?? ""
        }
    }
}
