import Foundation

enum SystemDNS {
    static let label = "com.macxelio.dns"
    static let plistPath = "/Library/LaunchDaemons/com.macxelio.dns.plist"
    static let configPath = Tools.dir.appendingPathComponent("dns.json")

    static func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    @discardableResult
    static func enable() -> Bool {
        writeConfig()

        if !isInstalled() {
            let tmpPlist = "/tmp/\(label).plist"
            try? plistContent().write(toFile: tmpPlist, atomically: true, encoding: .utf8)
            let installed = Shell.runAsRoot(
                """
                cp '\(tmpPlist)' '\(plistPath)'
                chown root:wheel '\(plistPath)'
                chmod 644 '\(plistPath)'
                launchctl bootout system/\(label) 2>/dev/null
                launchctl bootstrap system '\(plistPath)'
                """)
            guard installed else { return false }
        }

        return setSystemDNS("127.0.0.1")
    }

    @discardableResult
    static func disable() -> Bool {
        guard isInstalled() else {
            return setSystemDNS("empty")
        }
        let removed = Shell.runAsRoot(
            """
            launchctl bootout system/\(label) 2>/dev/null
            rm -f '\(plistPath)'
            """)
        guard removed else { return false }
        return setSystemDNS("empty")
    }

    static func writeConfig() {
        guard
            let data = try? JSONSerialization.data(
                withJSONObject: buildConfig(), options: [.prettyPrinted, .sortedKeys])
        else { return }
        if (try? Data(contentsOf: configPath)) != data {
            try? data.write(to: configPath)
        }
    }

    private static func buildConfig() -> [String: Any] {
        let app = AppConfig.shared
        var servers = app.dnsServerList.isEmpty ? ["1.1.1.1", "8.8.8.8"] : app.dnsServerList

        // A DoH server addressed by hostname needs a plain resolver to bootstrap its TLS host.
        let needsBootstrap = servers.contains { server in
            guard let host = Validator.dohHost(server) else { return false }
            return !Validator.isIP(host)
        }
        if needsBootstrap && !servers.contains(where: Validator.isIP) {
            servers.append("1.1.1.1")
        }

        var dns: [String: Any] = ["servers": servers]
        if !app.hosts.isEmpty {
            var hostMap: [String: String] = [:]
            for host in app.hosts { hostMap[host.domain] = host.address }
            dns["hosts"] = hostMap
        }

        return [
            "log": ["loglevel": "error"],
            "inbounds": [
                [
                    "tag": "dns-in",
                    "port": 53,
                    "listen": "127.0.0.1",
                    "protocol": "dokodemo-door",
                    "settings": ["address": "8.8.8.8", "port": 53, "network": "tcp,udp"],
                ]
            ],
            // "direct" is first so it is the default outbound: DoH/DoT queries the built-in
            // DNS client makes egress through freedom, while dns-in is routed to dns-out.
            "outbounds": [
                ["tag": "direct", "protocol": "freedom"],
                ["tag": "dns-out", "protocol": "dns"],
            ],
            "routing": [
                "rules": [["type": "field", "inboundTag": ["dns-in"], "outboundTag": "dns-out"]]
            ],
            "dns": dns,
        ]
    }

    private static func plistContent() -> String {
        let xray = Tools.url("xray").path
        let config = configPath.path
        let supervisor =
            "BIN=\"\(xray)\"; CFG=\"\(config)\"; "
            + "while true; do \"$BIN\" run -c \"$CFG\" &amp; PID=$!; STAMP=$(stat -f %m \"$CFG\"); "
            + "while kill -0 \"$PID\" 2&gt;/dev/null; do "
            + "if [ \"$(stat -f %m \"$CFG\")\" != \"$STAMP\" ]; then kill \"$PID\"; break; fi; "
            + "sleep 1; done; wait \"$PID\"; done"

        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key><string>\(label)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>/bin/sh</string>
                    <string>-c</string>
                    <string>\(supervisor)</string>
                </array>
                <key>RunAtLoad</key><true/>
                <key>KeepAlive</key><true/>
            </dict>
            </plist>
            """
    }

    @discardableResult
    private static func setSystemDNS(_ value: String) -> Bool {
        guard let service = Network.activeService() else { return false }
        return Shell.run("/usr/sbin/networksetup", ["-setdnsservers", service, value])
    }
}
