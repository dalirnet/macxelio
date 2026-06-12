import SwiftUI

struct HostFormView: View {
    @ObservedObject var appConfig: AppConfig
    var editingHost: Host?
    var onBack: () -> Void

    @State private var domain = ""
    @State private var address = ""

    var isEditing: Bool { editingHost != nil }

    private var domainError: String? {
        domain.isEmpty ? nil : Validator.domainError(domain)
    }

    private var addressError: String? {
        address.isEmpty ? nil : Validator.hostError(address)
    }

    var isValid: Bool {
        !domain.isEmpty && !address.isEmpty && domainError == nil && addressError == nil
    }

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: isEditing ? "Edit Host" : "Add Host") { onBack() }
            },
            headerRight: {
                SaveButton(disabled: !isValid) { saveHost() }
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        FormSection("Mapping", first: true)

                        FormFieldRow(label: "Domain", error: domainError) {
                            TextField("example.com", text: $domain)
                                .rowTextField()
                        }

                        FormFieldRow(label: "Address", error: addressError) {
                            TextField("178.22.122.100", text: $address)
                                .rowTextField()
                        }
                    }
                    .padding(16)
                }
            }
        )
        .onAppear {
            if let host = editingHost {
                domain = host.domain
                address = host.address
            }
        }
    }

    private func saveHost() {
        let host = Host(
            id: editingHost?.id ?? UUID(),
            domain: domain,
            address: address,
            createdAt: editingHost?.createdAt ?? Date()
        )

        if isEditing {
            appConfig.updateHost(host)
        } else {
            appConfig.addHost(host)
        }

        onBack()
    }
}
