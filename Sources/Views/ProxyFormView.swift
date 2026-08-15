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
    @State private var method = Proxy.defaultMethod
    @State private var username = ""
    @State private var security: Proxy.Security = .none
    @State private var sni = ""
    @State private var fingerprint = Proxy.defaultFingerprint
    @State private var flow = ""
    @State private var publicKey = ""
    @State private var shortId = ""
    @State private var spiderX = ""

    @State private var link = ""
    @State private var linkError: String?

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

    private var sniError: String? {
        sni.isEmpty ? nil : Validator.domainError(sni)
    }

    private var shortIdError: String? {
        shortId.isEmpty ? nil : Validator.shortIdError(shortId)
    }

    private var securityEnabled: Bool {
        type.supportsSecurity && security != .none
    }

    var isValid: Bool {
        guard !name.isEmpty && !address.isEmpty && !port.isEmpty else { return false }
        guard addressError == nil && portError == nil else { return false }

        if securityEnabled {
            guard sniError == nil && shortIdError == nil else { return false }
            if security == .reality && publicKey.isEmpty { return false }
        }

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
                        FormFieldRow(error: linkError) {
                            TextField("Paste a share link", text: $link)
                                .fullTextField()
                                .onSubmit { applyLink() }
                        }
                        .onChange(of: link) { _ in applyLink() }

                        FormSection("General")

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

                        if type.supportsSecurity {
                            FormSection("Transport")

                            SelectBox(
                                Proxy.Security.allCases.map { ($0, $0.rawValue) },
                                selection: $security,
                                label: "Security"
                            )

                            securityFields
                        }
                    }
                    .padding(16)
                }
            }
        )
        .onAppear {
            if let proxy = editingProxy { fill(from: proxy) }
        }
    }

    @ViewBuilder
    private var securityFields: some View {
        if security != .none {
            FormFieldRow(label: "SNI", error: sniError) {
                TextField(address.isEmpty ? "example.com" : address, text: $sni)
                    .rowTextField()
            }

            SelectBox(
                Proxy.fingerprints.map { ($0, $0) },
                selection: $fingerprint,
                label: "Fingerprint"
            )

            if type.supportsFlow {
                SelectBox(
                    Proxy.flows.map { ($0, $0.isEmpty ? "None" : $0) },
                    selection: $flow,
                    label: "Flow"
                )
            }

            if security == .reality {
                FormFieldRow(label: "Public Key") {
                    TextField("pbk", text: $publicKey)
                        .rowTextField()
                }

                FormFieldRow(label: "Short ID", error: shortIdError) {
                    TextField("sid (optional)", text: $shortId)
                        .rowTextField()
                }

                FormFieldRow(label: "SpiderX") {
                    TextField("/", text: $spiderX)
                        .rowTextField()
                }
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
                Proxy.shadowsocksMethods.map { ($0, $0) },
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

    private func fill(from proxy: Proxy) {
        name = proxy.name
        type = proxy.type
        address = proxy.address
        port = String(proxy.port)
        uuid = proxy.uuid ?? ""
        password = proxy.password ?? ""
        method = proxy.method ?? Proxy.defaultMethod
        username = proxy.username ?? ""
        security = proxy.security
        sni = proxy.sni ?? ""
        fingerprint = proxy.fingerprint ?? Proxy.defaultFingerprint
        flow = proxy.flow ?? ""
        publicKey = proxy.publicKey ?? ""
        shortId = proxy.shortId ?? ""
        spiderX = proxy.spiderX ?? ""
    }

    private func applyLink() {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            linkError = nil
            return
        }

        switch ProxyLink.parse(trimmed) {
        case .proxy(let proxy):
            fill(from: proxy)
            link = ""
            linkError = nil
        case .failure(let message):
            linkError = message
        }
    }

    private func saveProxy() {
        let secured = securityEnabled
        let reality = secured && security == .reality

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
            security: type.supportsSecurity ? security : .none,
            sni: secured && !sni.isEmpty ? sni : nil,
            fingerprint: secured ? fingerprint : nil,
            flow: secured && type.supportsFlow && !flow.isEmpty ? flow : nil,
            publicKey: reality && !publicKey.isEmpty ? publicKey : nil,
            shortId: reality && !shortId.isEmpty ? shortId : nil,
            spiderX: reality && !spiderX.isEmpty ? spiderX : nil,
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
