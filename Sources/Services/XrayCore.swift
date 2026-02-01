import Foundation

class XrayCore: ObservableObject {
    @Published var isRunning = false
    @Published var error: String?

    private var process: Process?

    private let configDir: URL
    private let binaryPath: URL
    private let configPath: URL

    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        configDir = homeDir.appendingPathComponent(".config/macxelio")
        binaryPath = configDir.appendingPathComponent("xray")
        configPath = configDir.appendingPathComponent("config.json")

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        // Listen for config changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configDidChange),
            name: .configDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stop()
    }

    @objc private func configDidChange() {
        if isRunning {
            restart()
        }
    }

    func start() {
        guard isInstalled() else {
            error = "Xray not installed"
            return
        }

        guard !isRunning else { return }

        let proc = Process()
        proc.executableURL = binaryPath
        proc.arguments = ["run", "-c", configPath.path]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice

        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.process = nil
            }
        }

        do {
            try proc.run()
            process = proc
            isRunning = true
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stop() {
        process?.terminate()
        process = nil
        isRunning = false
        error = nil
    }

    func restart() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.start()
        }
    }

    func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: binaryPath.path)
    }

    func getVersion() -> String? {
        guard isInstalled() else { return nil }

        let process = Process()
        process.executableURL = binaryPath
        process.arguments = ["version"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: "\n")
                if let firstLine = lines.first {
                    // "Xray 1.8.6 (Xray, Penetrates Everything.)"
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

    func getBinaryPath() -> String {
        binaryPath.path
    }

    func getConfigPath() -> String {
        configPath.path
    }

    func getConfigDir() -> URL {
        configDir
    }
}
