import SwiftUI

struct DNSPolicyFormView: View {
    @ObservedObject var appConfig: AppConfig
    var editingPolicy: DNSPolicy?
    var onBack: () -> Void

    @State private var domain = ""
    @State private var dnsServer = ""
    @State private var isTesting = false
    @State private var testResult: String?

    var isEditing: Bool { editingPolicy != nil }
    var isValid: Bool { !domain.isEmpty && !dnsServer.isEmpty }

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: isEditing ? "Edit Policy" : "Add Policy") { onBack() }
            },
            headerRight: {
                Button("Save") { savePolicy() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!isValid)
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        FormField(label: "Domain") {
                            TextField("geosite:ir or +.google.com", text: $domain)
                                .textFieldStyle(.roundedBorder)
                        }

                        FormField(label: "DNS Server") {
                            TextField("178.22.122.100", text: $dnsServer)
                                .textFieldStyle(.roundedBorder)
                        }

                        if let result = testResult {
                            Text(result)
                                .font(.caption)
                                .foregroundColor(result.contains("✓") ? .green : .red)
                        }
                    }
                    .padding(12)
                }
            },
            footerLeft: { EmptyView() },
            footerRight: {
                HStack(spacing: 8) {
                    if isTesting {
                        Spinner()
                    }

                    Button("Test") { testPolicy() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!isValid || isTesting)
                }
            }
        )
        .onAppear {
            if let policy = editingPolicy {
                domain = policy.domain
                dnsServer = policy.dnsServer
            }
        }
    }

    private func savePolicy() {
        let policy = DNSPolicy(
            id: editingPolicy?.id ?? UUID(),
            domain: domain,
            dnsServer: dnsServer,
            createdAt: editingPolicy?.createdAt ?? Date()
        )

        if isEditing {
            appConfig.updateDNSPolicy(policy)
        } else {
            appConfig.addDNSPolicy(policy)
        }

        onBack()
    }

    private func testPolicy() {
        isTesting = true
        testResult = nil

        Task {
            let success = await performTest()
            await MainActor.run {
                testResult = success ? "✓ Configuration valid" : "✗ Invalid configuration"
                isTesting = false
            }
        }
    }

    private func performTest() async -> Bool {
        let domainValid =
            domain.hasPrefix("geosite:") || domain.hasPrefix("+.") || domain.contains(".")
        let serverValid = dnsServer.contains(".") || dnsServer.hasPrefix("https://")
        return domainValid && serverValid
    }
}
