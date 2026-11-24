import AppKit

final class Tunnel {
    static let shared = Tunnel()

    static let configPath = Tools.url("tunnel.json")
    static let interface = "utun99"
    static let minimumXray = "26.6.27"

    static var isSupported: Bool {
        guard let version = Tools.xrayVersion() else { return false }
        return version.compare(minimumXray, options: .numeric) != .orderedAscending
    }

    private var timer: Timer?
    private var misses = 0

    static func writeConfig() {
        guard
            let data = try? JSONSerialization.data(
                withJSONObject: buildConfig(), options: [.prettyPrinted, .sortedKeys])
        else { return }
        if (try? Data(contentsOf: configPath)) != data {
            try? data.write(to: configPath, options: .atomic)
        }
    }

    func monitor(_ enabled: Bool) {
        timer?.invalidate()
        timer = nil
        misses = 0
        guard enabled else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Helper.queue.async {
                let running = Helper.isTunnelRunning()
                DispatchQueue.main.async { self?.checked(running) }
            }
        }
    }

    func updateXray() {
        let installed = Tools.xrayVersion() ?? "unknown"
        let confirmed = Self.alert(
            "System Tunnel needs a newer Xray",
            "System Tunnel requires Xray \(Self.minimumXray) or newer (installed: \(installed)).",
            buttons: ["Update Xray", "Cancel"])
        guard confirmed else { return }

        Task { @MainActor in
            let ok = await DownloadService().install(Tools.xray) { _ in }
            guard ok, Self.isSupported else {
                Self.alert("Xray update failed", "Check your connection and try again.")
                return
            }
            SystemSync.shared.retry()
            AppConfig.shared.tunnelEnabled = true
        }
    }

    private func checked(_ running: Bool) {
        guard timer != nil else { return }
        misses = running ? 0 : misses + 1
        guard misses >= 2 else { return }
        monitor(false)
        AppConfig.shared.tunnelEnabled = false
        Self.alert(
            "System Tunnel stopped unexpectedly", XrayCore.failureReason(log: Helper.tunnelLog))
    }

    @discardableResult
    private static func alert(_ title: String, _ message: String, buttons: [String] = ["OK"])
        -> Bool
    {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.icon = FlameIcon.createImage(size: 64, color: .systemOrange)
        buttons.forEach { alert.addButton(withTitle: $0) }
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static func buildConfig() -> [String: Any] {
        let routes = Network.hasGlobalIPv6() ? ["0.0.0.0/0", "::/0"] : ["0.0.0.0/0"]
        return [
            "inbounds": [
                [
                    "tag": "tun",
                    "port": 0,
                    "protocol": "tun",
                    "settings": [
                        "name": interface,
                        "mtu": 1500,
                        "autoSystemRoutingTable": routes,
                    ],
                    "sniffing": ["enabled": true, "destOverride": ["http", "tls", "quic"]],
                ]
            ],
            "outbounds": [
                [
                    "tag": "local",
                    "protocol": "socks",
                    "settings": [
                        "servers": [["address": "127.0.0.1", "port": AppConfig.shared.socksPort]]
                    ],
                ]
            ],
        ]
    }
}
