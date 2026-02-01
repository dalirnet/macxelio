import Foundation

@MainActor
class UpdateService: ObservableObject {
    @Published var appCurrentVersion: String = "1.0.0"
    @Published var appLatestVersion: String?
    @Published var xrayCurrentVersion: String?
    @Published var xrayLatestVersion: String?
    @Published var isChecking = false
    @Published var isUpdating = false
    @Published var progress: Double = 0
    @Published var currentStep: UpdateStep = .checking
    @Published var lastAppCheck: Date?
    @Published var lastXrayCheck: Date?

    private var downloadService: DownloadService?

    private let configDir: URL = {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent(".config/macxelio")
    }()

    enum UpdateStep: String {
        case checking = "Checking"
        case downloading = "Downloading"
        case installing = "Installing"
        case verifying = "Verifying"
        case done = "Done"
        case failed = "Failed"
    }

    private let appGithubRepo = "dalirnet/macxelio"
    private let xrayGithubRepo = "XTLS/Xray-core"

    init() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appCurrentVersion = version
        }

        Task {
            let version = await Task.detached { self.getXrayVersion() }.value
            self.xrayCurrentVersion = version
        }
    }

    func checkAppUpdate() async {
        isChecking = true

        do {
            let url = URL(string: "https://api.github.com/repos/\(appGithubRepo)/releases/latest")!
            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let tagName = json["tag_name"] as? String
            {
                let version = tagName.replacingOccurrences(of: "v", with: "")
                appLatestVersion = version
                lastAppCheck = Date()
            }
        } catch {
            // Silently fail
        }

        isChecking = false
    }

    func cancelCheck() {
        isChecking = false
    }

    func checkXrayUpdate() async {
        isChecking = true

        do {
            let url = URL(string: "https://api.github.com/repos/\(xrayGithubRepo)/releases/latest")!
            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let tagName = json["tag_name"] as? String
            {
                let version = tagName.replacingOccurrences(of: "v", with: "")
                xrayLatestVersion = version
                lastXrayCheck = Date()
            }
        } catch {
            // Silently fail
        }

        isChecking = false
    }

    func updateXray() async throws {
        isUpdating = true
        currentStep = .downloading
        progress = 0

        let arch = DownloadService.getArchitecture()
        let downloadURL =
            "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-macos-\(arch).zip"

        guard let url = URL(string: downloadURL) else {
            currentStep = .failed
            isUpdating = false
            throw UpdateError.downloadFailed
        }

        let tempZipPath = configDir.appendingPathComponent("xray.zip")
        let xrayBinaryPath = configDir.appendingPathComponent("xray")

        let service = DownloadService()
        downloadService = service

        do {
            let localURL: URL = try await withCheckedThrowingContinuation { continuation in
                service.download(
                    from: url,
                    progress: { [weak self] progress, _ in
                        Task { @MainActor in
                            self?.progress = progress * 0.7
                        }
                    },
                    completion: { result in
                        continuation.resume(with: result)
                    })
            }

            try? FileManager.default.removeItem(at: tempZipPath)
            try FileManager.default.moveItem(at: localURL, to: tempZipPath)

            currentStep = .installing
            progress = 0.8

            let success = await DownloadService.extractZip(tempZipPath, to: configDir)
            try? FileManager.default.removeItem(at: tempZipPath)

            if success {
                try? FileManager.default.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: xrayBinaryPath.path
                )

                currentStep = .verifying
                progress = 0.9

                xrayCurrentVersion = getXrayVersion()

                currentStep = .done
                progress = 1.0
                isUpdating = false
            } else {
                throw UpdateError.installFailed
            }

        } catch {
            currentStep = .failed
            isUpdating = false
            throw error
        }
    }

    var appUpdateAvailable: Bool {
        guard let latest = appLatestVersion else { return false }
        return compareVersions(appCurrentVersion, latest) < 0
    }

    var xrayUpdateAvailable: Bool {
        guard let current = xrayCurrentVersion, let latest = xrayLatestVersion else { return false }
        return compareVersions(current, latest) < 0
    }

    var lastAppCheckFormatted: String {
        guard let date = lastAppCheck else { return "Never" }
        return formatTimeAgo(date)
    }

    var lastXrayCheckFormatted: String {
        guard let date = lastXrayCheck else { return "Never" }
        return formatTimeAgo(date)
    }

    nonisolated private func getXrayVersion() -> String? {
        let xrayPath = configDir.appendingPathComponent("xray")

        guard FileManager.default.fileExists(atPath: xrayPath.path) else { return nil }

        let process = Process()
        process.executableURL = xrayPath
        process.arguments = ["version"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: "\n")
                if let firstLine = lines.first {
                    let parts = firstLine.components(separatedBy: " ")
                    if parts.count >= 2 {
                        return parts[1]
                    }
                }
            }
        } catch {
            return nil
        }

        return nil
    }

    nonisolated private func compareVersions(_ v1: String, _ v2: String) -> Int {
        let parts1 = v1.components(separatedBy: ".").compactMap { Int($0) }
        let parts2 = v2.components(separatedBy: ".").compactMap { Int($0) }

        for i in 0..<max(parts1.count, parts2.count) {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0

            if p1 < p2 { return -1 }
            if p1 > p2 { return 1 }
        }

        return 0
    }

    nonisolated private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hours ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) days ago"
        }
    }
}

enum UpdateError: Error {
    case downloadFailed
    case installFailed
}
