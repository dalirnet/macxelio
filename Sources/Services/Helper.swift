import Foundation

enum Helper {
    static let queue = DispatchQueue(label: label)

    static let tunnelLog = URL(fileURLWithPath: "\(rootDir)/tunnel.log")

    struct Firewall: Equatable {
        var quic = false
        var webrtc = false
        var allow: [String] = []

        static let off = Firewall()

        var isOff: Bool { !quic && !webrtc }

        fileprivate var content: String {
            guard !isOff else { return "" }
            let flags = [quic ? "quic" : nil, webrtc ? "webrtc" : nil].compactMap { $0 }
            return ([flags.joined(separator: " ")] + (webrtc ? allow : [])).joined(separator: "\n")
        }
    }

    private static let rootDir = "/Library/PrivilegedHelperTools/com.macxelio"
    private static let label = "com.macxelio.helper"
    private static let plistPath = "/Library/LaunchDaemons/\(label).plist"
    private static let scriptPath = "\(rootDir)/helper.sh"
    private static let xrayPath = "\(rootDir)/xray"
    private static let legacyLabels = ["com.macxelio.quic", "com.macxelio.dns"]
    private static let legacyFiles = ["/Library/PrivilegedHelperTools/\(label).sh"]

    private static let tunnelMarker = Tools.url("tunnel.on")
    private static let dnsMarker = Tools.url("dns.on")
    private static let firewallMarker = Tools.url("firewall")

    private static var xrayCheck: (stamp: String, matches: Bool)?

    static func isInstalled() -> Bool {
        guard let script = script() else { return false }
        let legacy = legacyLabels.contains {
            FileManager.default.fileExists(atPath: "/Library/LaunchDaemons/\($0).plist")
        }
        return !legacy && FileManager.default.fileExists(atPath: plistPath)
            && (try? String(contentsOfFile: scriptPath, encoding: .utf8)) == script
            && xrayMatches() && isLoaded()
    }

    private static func isLoaded() -> Bool {
        Shell.run("/bin/launchctl", ["print", "system/\(label)"])
    }

    static func install() -> Bool {
        if isInstalled() { return true }
        guard let script = script(), let xray = Tools.path(Tools.xray) else { return false }

        let tmp = FileManager.default.temporaryDirectory
        let tmpScript = tmp.appendingPathComponent("\(label).sh").path
        let tmpPlist = tmp.appendingPathComponent("\(label).plist").path
        guard (try? script.write(toFile: tmpScript, atomically: true, encoding: .utf8)) != nil,
            (try? plist().write(toFile: tmpPlist, atomically: true, encoding: .utf8)) != nil
        else { return false }

        let legacy =
            legacyLabels.map {
                "launchctl bootout system/\($0) 2>/dev/null; rm -f '/Library/LaunchDaemons/\($0).plist'"
            } + legacyFiles.map { "rm -f '\($0)'" }
        let loaded = "launchctl print system/\(label) >/dev/null 2>&1"
        let steps = [
            "launchctl bootout system/\(label) 2>/dev/null",
            "for i in $(seq 50); do \(loaded) || break; sleep 0.1; done",
            "mkdir -p '\(rootDir)'",
            "chown root:wheel '\(rootDir)'",
            "chmod 755 '\(rootDir)'",
            "cp '\(tmpScript)' '\(scriptPath)'",
            "cp '\(xray)' '\(xrayPath)'",
            "chown root:wheel '\(scriptPath)' '\(xrayPath)'",
            "chmod 755 '\(scriptPath)' '\(xrayPath)'",
            "cp '\(tmpPlist)' '\(plistPath)'",
            "chown root:wheel '\(plistPath)'",
            "chmod 644 '\(plistPath)'",
            "for i in $(seq 5); do launchctl bootstrap system '\(plistPath)' 2>/dev/null && break; sleep 1; done",
            loaded,
        ]
        xrayCheck = nil
        return Shell.runAsRoot((legacy + steps).joined(separator: "\n"))
    }

    static func setFirewall(_ firewall: Firewall) {
        let content = firewall.content
        let current = (try? String(contentsOf: firewallMarker, encoding: .utf8)) ?? ""
        guard content != current else { return }
        if content.isEmpty {
            remove(firewallMarker)
        } else {
            try? content.write(to: firewallMarker, atomically: true, encoding: .utf8)
        }
    }

    static var isDNSOn: Bool {
        FileManager.default.fileExists(atPath: dnsMarker.path)
    }

    static func setDNS(_ enabled: Bool) {
        if !enabled {
            remove(dnsMarker)
        } else if !isDNSOn {
            try? Data().write(to: dnsMarker)
        }
    }

    static func startTunnel() {
        try? UUID().uuidString.write(to: tunnelMarker, atomically: true, encoding: .utf8)
    }

    static func stopTunnel() {
        remove(tunnelMarker)
    }

    static func isTunnelRunning() -> Bool {
        Shell.run("/usr/bin/pgrep", ["-U", "0", "-f", "xray run -c \(Tunnel.configPath.path)"])
    }

    private static func xrayMatches() -> Bool {
        guard let source = Tools.path(Tools.xray),
            let attrs = try? FileManager.default.attributesOfItem(atPath: source)
        else { return false }
        let stamp = "\(attrs[.size] ?? 0)-\(attrs[.modificationDate] ?? "")"
        if let check = xrayCheck, check.stamp == stamp { return check.matches }
        let matches = FileManager.default.contentsEqual(atPath: source, andPath: xrayPath)
        xrayCheck = (stamp, matches)
        return matches
    }

    private static func remove(_ marker: URL) {
        try? FileManager.default.removeItem(at: marker)
    }

    private static func script() -> String? {
        guard let url = Bundle.main.url(forResource: "helper", withExtension: "sh"),
            let template = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        return
            template
            .replacingOccurrences(of: "__DIR__", with: Tools.dir.path)
            .replacingOccurrences(of: "__ROOT__", with: rootDir)
    }

    private static func plist() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key><string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>/bin/sh</string>
                <string>\(scriptPath)</string>
            </array>
            <key>RunAtLoad</key><true/>
            <key>KeepAlive</key><true/>
        </dict>
        </plist>
        """
    }
}
