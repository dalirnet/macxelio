import AppKit

class XrayCore: ObservableObject {
    @Published var isRunning = false
    @Published var isRestarting = false
    @Published var error: String?

    private var process: Process?

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

        Shell.run(
            "/usr/bin/pkill", ["-U", "\(getuid())", "-f", "xray run -c \(Tools.config.path)"])
        try? Data().write(to: Tools.accessLog)
        try? Data().write(to: Tools.bootLog)
        let bootHandle = try? FileHandle(forWritingTo: Tools.bootLog)

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: xrayPath)
        proc.arguments = ["run", "-c", Tools.config.path]
        proc.standardOutput = bootHandle ?? FileHandle.nullDevice
        proc.standardError = bootHandle ?? FileHandle.nullDevice

        if let assets = Tools.xrayAssetDir() {
            var env = ProcessInfo.processInfo.environment
            env["XRAY_LOCATION_ASSET"] = assets
            proc.environment = env
        }

        proc.terminationHandler = { [weak self] terminated in
            try? bootHandle?.close()
            DispatchQueue.main.async {
                guard let self, self.process === terminated else { return }
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

    static func failureReason(log bootLog: URL) -> String {
        let fallback =
            "Xray could not start. Check the configuration and that the required ports are free."
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
            guard let port else { return "A required port is already in use by another app." }
            let owner = Network.portOwner(port).map { " by \($0)" } ?? " by another app"
            return
                "Port \(port) is already in use\(owner). Quit that app or free the port, then restart."
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
            AppConfig.apiPort, AppConfig.testPort,
            AppConfig.shared.httpPort, AppConfig.shared.socksPort,
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
        let reason = Self.failureReason(log: Tools.bootLog)
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
        let previous = process
        stop()
        DispatchQueue.global().async { [weak self] in
            let deadline = Date().addingTimeInterval(5)
            while Date() < deadline && previous?.isRunning == true {
                Thread.sleep(forTimeInterval: 0.1)
            }
            DispatchQueue.main.async {
                self?.start()
                self?.isRestarting = false
            }
        }
    }

    func isInstalled() -> Bool {
        Tools.isInstalled(Tools.xray)
    }

    func getVersion() -> String? {
        Tools.xrayVersion()
    }
}
