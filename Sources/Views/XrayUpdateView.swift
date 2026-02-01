import SwiftUI

struct XrayUpdateView: View {
    var onBack: () -> Void

    @StateObject private var updateService = UpdateService()

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Xray Update") { onBack() }
                    .disabled(updateService.isChecking)
            },
            headerRight: { EmptyView() },
            content: {
                VStack(spacing: 16) {
                    statusIcon

                    Text("Xray Core")
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
            await updateService.checkXrayUpdate()
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if updateService.isChecking {
            StatusIcon(status: .loading)
        } else if updateService.xrayUpdateAvailable {
            StatusIcon(status: .warning)
        } else if updateService.xrayLatestVersion != nil {
            StatusIcon(status: .success)
        } else {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
        }
    }

    private var subtitleText: String {
        if updateService.isChecking {
            return "Checking for updates"
        } else if updateService.xrayUpdateAvailable {
            return
                "v\(updateService.xrayCurrentVersion ?? "") → v\(updateService.xrayLatestVersion ?? "")"
        } else if updateService.xrayLatestVersion != nil {
            return "v\(updateService.xrayCurrentVersion ?? "") is up to date"
        } else if updateService.xrayCurrentVersion != nil {
            return "v\(updateService.xrayCurrentVersion ?? "")"
        } else {
            return "Not installed"
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
        } else if updateService.xrayUpdateAvailable {
            Button("Update") {
                Task { try? await updateService.updateXray() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        } else {
            Button("Check") {
                Task { await updateService.checkXrayUpdate() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}
