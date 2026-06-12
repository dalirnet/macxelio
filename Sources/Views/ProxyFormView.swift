import SwiftUI

struct ProxyFormView: View {
    @ObservedObject var appConfig: AppConfig
    var editingProxy: Proxy?
    var onBack: () -> Void

    @State private var name = ""
    @State private var type: Proxy.ProxyType = .shadowsocks
    @State private var address = ""
    @State private var port = "443"
    @State private var uuid = ""
    @State private var password = ""
    @State private var method = "aes-256-gcm"
    @State private var username = ""

    private let shadowsocksMethods = [
        "aes-128-gcm",
        "aes-256-gcm",
        "chacha20-poly1305",
    ]

    var isEditing: Bool { editingProxy != nil }

    private var authOptional: Bool {
        switch type {
        case .socks, .http: return true
        default: return false
        }
    }

    private var addressError: String? {
        address.isEmpty ? nil : Validator.hostError(address)
    }

    private var portError: String? {
        port.isEmpty ? nil : Validator.portError(port)
    }

    private var uuidError: String? {
        switch type {
        case .vless, .vmess:
            return uuid.isEmpty ? nil : Validator.uuidError(uuid)
        default:
            return nil
        }
    }

    var isValid: Bool {
        guard !name.isEmpty && !address.isEmpty && !port.isEmpty else { return false }
        guard addressError == nil && portError == nil else { return false }

        switch type {
        case .vless, .vmess:
            return !uuid.isEmpty && uuidError == nil
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
                BackButton(title: isEditing ? "Edit Proxy" : "Add Proxy") { onBack() }
            },
            headerRight: {
                SaveButton(disabled: !isValid) { saveProxy() }
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        FormSection("General", first: true)

                        FormFieldRow(label: "Name") {
                            TextField("My Server", text: $name)
                                .rowTextField()
                        }

                        SelectBox(
                            Proxy.ProxyType.allCases.map { ($0, $0.rawValue) },
                            selection: $type,
                            label: "Type"
                        )

                        FormSection("Server")

                        FormFieldRow(label: "Address", error: addressError) {
                            TextField("example.com", text: $address)
                                .rowTextField()
                        }

                        FormFieldRow(label: "Port", error: portError) {
                            TextField("443", text: $port)
                                .rowTextField()
                        }

                        FormSection(authOptional ? "Authentication (Optional)" : "Authentication")

                        dynamicFields
                    }
                    .padding(16)
                }
            }
        )
        .onAppear {
            if let proxy = editingProxy {
                name = proxy.name
                type = proxy.type
                address = proxy.address
                port = String(proxy.port)
                uuid = proxy.uuid ?? ""
                password = proxy.password ?? ""
                method = proxy.method ?? "aes-256-gcm"
                username = proxy.username ?? ""
            }
        }
    }

    @ViewBuilder
    private var dynamicFields: some View {
        switch type {
        case .vless, .vmess:
            FormFieldRow(label: "UUID", error: uuidError) {
                TextField("00000000-0000-0000-0000-000000000000", text: $uuid)
                    .rowTextField()
            }

        case .trojan:
            FormFieldRow(label: "Password") {
                TextField("Password", text: $password)
                    .rowTextField()
            }

        case .shadowsocks:
            FormFieldRow(label: "Password") {
                TextField("Password", text: $password)
                    .rowTextField()
            }

            SelectBox(
                shadowsocksMethods.map { ($0, $0) },
                selection: $method,
                label: "Method"
            )

        case .socks, .http:
            FormFieldRow(label: "Username") {
                TextField("Username", text: $username)
                    .rowTextField()
            }

            FormFieldRow(label: "Password") {
                TextField("Password", text: $password)
                    .rowTextField()
            }
        }
    }

    private func saveProxy() {
        let proxy = Proxy(
            id: editingProxy?.id ?? UUID(),
            name: name,
            type: type,
            address: address,
            port: Int(port) ?? 443,
            uuid: uuid.isEmpty ? nil : uuid,
            password: password.isEmpty ? nil : password,
            method: method.isEmpty ? nil : method,
            username: username.isEmpty ? nil : username,
            createdAt: editingProxy?.createdAt ?? Date()
        )

        if isEditing {
            appConfig.updateProxy(proxy)
        } else {
            appConfig.addProxy(proxy)
        }

        onBack()
    }
}
