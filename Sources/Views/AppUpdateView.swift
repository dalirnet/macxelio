import SwiftUI

struct AppUpdateView: View {
    var onBack: () -> Void

    @StateObject private var updateService = UpdateService()

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "App Update") { onBack() }
                    .disabled(updateService.isChecking)
            },
            headerRight: { EmptyView() },
            content: {
                VStack(spacing: 16) {
                    statusIcon

                    Text("Macxelio")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(subtitleText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            },
            footerLeft: { EmptyView() },
            footerRight: { actionButton }
        )
        .task {
            await updateService.checkAppUpdate()
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if updateService.isChecking {
            StatusIcon(status: .loading)
        } else if updateService.appUpdateAvailable {
            StatusIcon(status: .warning)
        } else if updateService.appLatestVersion != nil {
            StatusIcon(status: .success)
        } else {
            Image(systemName: "app.badge")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
        }
    }

    private var subtitleText: String {
        if updateService.isChecking {
            return "Checking for updates"
        } else if updateService.appUpdateAvailable {
            return "v\(updateService.appCurrentVersion) → v\(updateService.appLatestVersion ?? "")"
        } else if updateService.appLatestVersion != nil {
            return "v\(updateService.appCurrentVersion) is up to date"
        } else {
            return "v\(updateService.appCurrentVersion)"
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if updateService.isChecking {
            Button("Cancel") {
                updateService.cancelCheck()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        } else if updateService.appUpdateAvailable {
            Button("Download") {
                if let url = URL(string: "https://github.com/user/macxelio/releases/latest") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        } else {
            Button("Check") {
                Task { await updateService.checkAppUpdate() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}
