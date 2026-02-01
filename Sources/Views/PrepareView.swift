import SwiftUI

struct PrepareView: View {
    var onComplete: () -> Void

    @State private var installStatus: InstallStatus = .ready
    @State private var downloadProgress: Double = 0
    @State private var downloadedBytes: Int64 = 0
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    @State private var isCancelling = false
    @State private var downloadService: DownloadService?

    private let configDir: URL = {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent(".config/macxelio")
    }()

    enum InstallStatus {
        case ready
        case downloading
        case extracting
        case done
        case failed(String)
    }

    var body: some View {
        ViewLayout(
            headerLeft: {
                HeaderTitle(title: "Prepare", showFlame: true)
            },
            headerRight: { EmptyView() },
            content: {
                VStack(spacing: 16) {
                    if case .ready = installStatus {
                        readyContent
                    } else {
                        installingContent
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: installStatusKey)
            },
            footerLeft: { EmptyView() },
            footerRight: { footerButton }
        )
    }

    // MARK: - Content Views

    private var readyContent: some View {
        Group {
            FlameIconView(isActive: true, size: 64)
                .frame(width: 64, height: 64)

            Text("Install Xray Core")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Download and install Xray Core")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .transition(.opacity)
    }

    private var installingContent: some View {
        Group {
            StatusIcon(status: installStatusIcon)

            Text(installStatusText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            if case .downloading = installStatus {
                VStack(spacing: 8) {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 150)

                    HStack {
                        Text(formatBytes(downloadedBytes))
                        Spacer()
                        Text(formatTime(elapsedSeconds))
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 150)
                }
            } else if case .extracting = installStatus {
                ProgressView()
                    .progressViewStyle(.linear)
                    .frame(width: 150)
            }

            if case .failed(let message) = installStatus {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private var footerButton: some View {
        if case .ready = installStatus {
            Button("Continue") {
                Task { await downloadXray() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        } else if case .failed = installStatus {
            Button("Retry") {
                Task { await downloadXray() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        } else if case .done = installStatus {
            Button("Done") {
                onComplete()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        } else {
            Button("Cancel") { cancelDownload() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private var installStatusKey: String {
        switch installStatus {
        case .ready: return "ready"
        case .downloading: return "downloading"
        case .extracting: return "extracting"
        case .done: return "done"
        case .failed: return "failed"
        }
    }

    private var installStatusIcon: StatusIcon.Status {
        switch installStatus {
        case .done: return .success
        case .failed: return .error
        default: return .loading
        }
    }

    private var installStatusText: String {
        switch installStatus {
        case .ready: return "Ready"
        case .downloading: return "Downloading Xray Core"
        case .extracting: return "Extracting"
        case .done: return "Installation complete"
        case .failed: return "Installation failed"
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        if mb >= 1 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.0f KB", kb)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func startTimer() {
        elapsedSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func downloadXray() async {
        installStatus = .downloading
        downloadProgress = 0
        downloadedBytes = 0
        startTimer()

        let arch = DownloadService.getArchitecture()
        let downloadURL =
            "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-macos-\(arch).zip"

        guard let url = URL(string: downloadURL) else {
            stopTimer()
            installStatus = .failed("Invalid URL")
            return
        }

        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        let tempZipPath = configDir.appendingPathComponent("xray.zip")
        let xrayBinaryPath = configDir.appendingPathComponent("xray")

        let service = DownloadService()
        downloadService = service

        do {
            let localURL: URL = try await withCheckedThrowingContinuation { continuation in
                service.download(
                    from: url,
                    progress: { progress, bytes in
                        DispatchQueue.main.async {
                            self.downloadProgress = progress
                            self.downloadedBytes = bytes
                        }
                    },
                    completion: { result in
                        continuation.resume(with: result)
                    })
            }

            stopTimer()

            try? FileManager.default.removeItem(at: tempZipPath)
            try FileManager.default.moveItem(at: localURL, to: tempZipPath)

            await MainActor.run { installStatus = .extracting }

            let success = await DownloadService.extractZip(tempZipPath, to: configDir)

            try? FileManager.default.removeItem(at: tempZipPath)

            if success {
                try? FileManager.default.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: xrayBinaryPath.path
                )

                if FileManager.default.fileExists(atPath: xrayBinaryPath.path) {
                    await MainActor.run { installStatus = .done }
                } else {
                    await MainActor.run {
                        installStatus = .failed("Binary not found after extraction")
                    }
                }
            } else {
                await MainActor.run { installStatus = .failed("Extraction failed") }
            }

        } catch let error as NSError {
            stopTimer()
            if isCancelling {
                await MainActor.run {
                    isCancelling = false
                    installStatus = .ready
                }
                return
            }
            let message = error.localizedDescription
            await MainActor.run { installStatus = .failed(message) }
        }
    }

    private func cancelDownload() {
        isCancelling = true
        downloadService?.cancel()
        downloadService = nil
        stopTimer()
    }
}
