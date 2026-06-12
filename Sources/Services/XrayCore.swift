import AppKit

class XrayCore: ObservableObject {
    @Published var isRunning = false
    @Published var isRestarting = false
    @Published var error: String?

    private var process: Process?

    private let configPath = Tools.url("config.json")

    init() {
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
        } else {
            start()
        }
    }

    func start() {
        guard let xrayPath = Tools.path(Tools.xray) else {
            error = "xray not installed"
            return
        }

        guard !isRunning else { return }

        killStrayInstances()

        try? Data().write(to: Tools.url("access.log"))

        let bootLog = Tools.url("boot.log")
        try? Data().write(to: bootLog)
        let bootHandle = try? FileHandle(forWritingTo: bootLog)

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: xrayPath)
        proc.arguments = ["run", "-c", configPath.path]
        proc.standardOutput = bootHandle ?? FileHandle.nullDevice
        proc.standardError = bootHandle ?? FileHandle.nullDevice

        if let assets = Tools.xrayAssetDir() {
            var env = ProcessInfo.processInfo.environment
            env["XRAY_LOCATION_ASSET"] = assets
            proc.environment = env
        }

        proc.terminationHandler = { [weak self] _ in
            try? bootHandle?.close()
            DispatchQueue.main.async {
                guard let self else { return }
                let unexpected = self.isRunning
                self.isRunning = false
                self.process = nil
                if unexpected { self.alertFailure() }
            }
        }

        do {
            try proc.run()
            process = proc
            isRunning = true
            error = nil
        } catch {
            try? bootHandle?.close()
            self.error = error.localizedDescription
            alertFailure()
        }
    }

    private func killStrayInstances() {
        Shell.run("/usr/bin/pkill", ["-f", "xray run -c \(configPath.path)"])
    }

    private func failureReason() -> String {
        let fallback =
            "Xray could not start. Check the configuration and that the required ports are free."
        let bootLog = Tools.url("boot.log")
        guard let log = try? String(contentsOf: bootLog, encoding: .utf8) else { return fallback }

        let segments =
            log
            .components(separatedBy: "\n")
            .flatMap { $0.components(separatedBy: " > ") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !Self.isNoise($0) }
        guard !segments.isEmpty else { return fallback }

        let text = segments.joined(separator: "\n").lowercased()
        let port = Self.knownPort(in: text)

        if text.contains("address already in use") {
            return port.map {
                "Port \($0) is already in use by another app. Quit that app or free the port, then restart."
            } ?? "A required port is already in use by another app."
        }
        if text.contains("permission denied") {
            return port.map {
                "Permission denied opening port \($0). Ports below 1024 require elevated privileges."
            } ?? "Permission denied while opening a required port."
        }
        if let ip = Self.value(after: "invalid ip", in: segments) {
            return "A rule contains an invalid IP or CIDR: “\(ip)”. Fix the rule and try again."
        }
        if let domain = Self.value(after: "invalid domain", in: segments) {
            return "A rule contains an invalid domain: “\(domain)”. Fix the rule and try again."
        }
        if let addr = Self.value(after: "unsupported address for router", in: segments) {
            return "A rule contains an invalid address: “\(addr)”. Fix the rule and try again."
        }
        if text.contains("invalid field rule") || text.contains("failed to build routing") {
            return "A routing rule is invalid. Check its values and try again."
        }
        if text.contains("failed to parse json") || text.contains("invalid character")
            || text.contains("unexpected end of json")
        {
            return "The configuration is not valid JSON. Review the proxy settings and try again."
        }
        if text.contains("unknown protocol") || text.contains("unable to create proxy")
            || text.contains("failed to create")
        {
            return "A proxy in the configuration uses an unsupported or misconfigured protocol."
        }
        if text.contains("no such file") || text.contains("cannot find") {
            return "A required file is missing. Reinstall Xray from Settings and try again."
        }

        return Self.cleanCause(segments[segments.count - 1])
    }

    private static func isNoise(_ line: String) -> Bool {
        if line.hasPrefix("Xray ") || line.hasPrefix("A unified") { return true }
        let lower = line.lowercased()
        return lower.contains("[warning]") || lower.contains("[info]")
            || lower.contains("[debug]") || lower.contains("deprecated")
            || lower.contains("not recommended")
    }

    private static func knownPort(in text: String) -> Int? {
        let ports = [
            AppConfig.apiPort, AppConfig.testPort, AppConfig.httpPort, AppConfig.socksPort,
        ]
        return ports.first { text.contains("\($0)") }
    }

    private static func value(after keyword: String, in segments: [String]) -> String? {
        for segment in segments {
            guard let range = segment.range(of: keyword, options: .caseInsensitive) else {
                continue
            }
            let value = segment[range.upperBound...]
                .trimmingCharacters(in: CharacterSet(charactersIn: " :.,\"'“”"))
            if !value.isEmpty { return value }
        }
        return nil
    }

    private static func cleanCause(_ segment: String) -> String {
        var msg = segment
        while let colon = msg.firstIndex(of: ":"), msg[msg.startIndex..<colon].contains("/") {
            msg = String(msg[msg.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        }
        guard let first = msg.first else { return msg }
        msg = first.uppercased() + msg.dropFirst()
        if !msg.hasSuffix(".") { msg += "." }
        return msg
    }

    private func alertFailure() {
        let reason = failureReason()
        error = reason

        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Xray stopped unexpectedly"
        alert.informativeText = reason
        alert.alertStyle = .warning
        alert.icon = FlameIcon.createImage(size: 64, color: .systemOrange)
        alert.addButton(withTitle: "Restart")
        alert.addButton(withTitle: "Dismiss")
        if alert.runModal() == .alertFirstButtonReturn {
            restart()
        }
    }

    func stop() {
        process?.terminate()
        process = nil
        isRunning = false
        error = nil
    }

    func restart() {
        isRestarting = true
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.start()
            self?.isRestarting = false
        }
    }

    func isInstalled() -> Bool {
        Tools.isInstalled(Tools.xray)
    }

    func getVersion() -> String? {
        guard let xrayPath = Tools.path(Tools.xray) else { return nil }
        let parts = Shell.output(xrayPath, ["version"])
            .components(separatedBy: "\n").first?.components(separatedBy: " ")
        guard let parts, parts.count >= 2 else { return nil }
        return parts[1]
    }
}
