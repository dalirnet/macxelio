import SwiftUI

struct HelpView: View {
    @ObservedObject var xrayCore: XrayCore
    var onBack: () -> Void

    @State private var xrayVersion = "—"

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Help") { onBack() }
            },
            headerRight: {
                HeaderButton(icon: "arrow.up.right.square", help: "GitHub") {
                    if let url = URL(string: "https://github.com/dalirnet/macxelio") {
                        NSWorkspace.shared.open(url)
                    }
                }
            },
            content: {
                ScrollView {
                    VStack(spacing: 0) {
                        InfoRow(label: "Xray Core", value: xrayVersion)
                        Divider()
                        InfoRow(label: "App Version", value: appVersion)
                    }
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                    .padding(16)
                }
            }
        )
        .onAppear {
            xrayVersion = xrayCore.getVersion() ?? "Not installed"
        }
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
