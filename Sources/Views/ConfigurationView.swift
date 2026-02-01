import SwiftUI

struct ConfigurationView: View {
    var onComplete: () -> Void

    @State private var socksPort: String = "10808"
    @State private var httpPort: String = "10809"

    var body: some View {
        ViewLayout(
            headerLeft: {
                HeaderTitle(title: "Configuration", showFlame: true)
            },
            headerRight: { EmptyView() },
            content: {
                VStack(spacing: 16) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Port Configuration")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 12) {
                        FormField(label: "SOCKS Port") {
                            TextField("10808", text: $socksPort)
                                .textFieldStyle(.roundedBorder)
                        }

                        FormField(label: "HTTP Port") {
                            TextField("10809", text: $httpPort)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .frame(width: 200)
                    .padding(.top, 8)
                }
            },
            footerLeft: { EmptyView() },
            footerRight: {
                Button("Done") {
                    saveConfiguration()
                    onComplete()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        )
    }

    private func saveConfiguration() {
        let appConfig = AppConfig.shared
        if let socks = Int(socksPort) {
            appConfig.socksPort = socks
        }
        if let http = Int(httpPort) {
            appConfig.httpPort = http
        }
        appConfig.save()
    }
}
