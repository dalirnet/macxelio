import SwiftUI

struct DNSServerFormView: View {
    @ObservedObject var appConfig: AppConfig
    var editingServer: DNSServer?
    var onBack: () -> Void

    @State private var address = ""
    @State private var isTesting = false
    @State private var testResult: String?

    var isEditing: Bool { editingServer != nil }
    var isValid: Bool { !address.isEmpty }

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: isEditing ? "Edit Server" : "Add Server") { onBack() }
            },
            headerRight: {
                Button("Save") { saveServer() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!isValid)
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        FormField(label: "Address") {
                            TextField("8.8.8.8 or https://dns.google/dns-query", text: $address)
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

                    Button("Test") { testDNS() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(address.isEmpty || isTesting)
                }
            }
        )
        .onAppear {
            if let server = editingServer {
                address = server.address
            }
        }
    }

    private func saveServer() {
        let server = DNSServer(
            id: editingServer?.id ?? UUID(),
            address: address,
            createdAt: editingServer?.createdAt ?? Date()
        )

        if isEditing {
            appConfig.updateDNSServer(server)
        } else {
            appConfig.addDNSServer(server)
        }

        onBack()
    }

    private func testDNS() {
        isTesting = true
        testResult = nil

        Task {
            let success = await performDNSTest()
            await MainActor.run {
                testResult = success ? "✓ DNS server reachable" : "✗ Cannot reach DNS server"
                isTesting = false
            }
        }
    }

    private func performDNSTest() async -> Bool {
        if address.hasPrefix("https://") {
            guard let url = URL(string: address) else { return false }
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
                return (response as? HTTPURLResponse)?.statusCode == 200
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                let task = URLSession.shared.streamTask(withHostName: address, port: 53)
                task.resume()
                task.readData(ofMinLength: 0, maxLength: 1, timeout: 3) { _, _, error in
                    task.cancel()
                    continuation.resume(returning: error == nil)
                }
            }
        }
    }
}
