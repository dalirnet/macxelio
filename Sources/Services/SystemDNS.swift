import Foundation

enum SystemDNS {
    static let label = "com.macxelio.dns"
    static let plistPath = "/Library/LaunchDaemons/com.macxelio.dns.plist"
    static let configPath = Tools.dir.appendingPathComponent("dns.json")

    private static let internalTag = "dns-internal"
    private static let fallbackServer = "1.1.1.1"

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
        let servers = app.dnsServerList.isEmpty ? [fallbackServer, "8.8.8.8"] : app.dnsServerList
        let viaProxy =
            app.proxyMode != .direct
            && app.proxies.contains { $0.id == app.selectedProxyId }
            && servers.contains { $0.lowercased().hasPrefix("https://") }

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
            "outbounds": buildOutbounds(viaProxy: viaProxy),
            "routing": buildRouting(viaProxy: viaProxy),
            "dns": buildDNS(servers: servers, viaProxy: viaProxy),
        ]
    }

    private static func buildDNS(servers: [String], viaProxy: Bool) -> [String: Any] {
        let app = AppConfig.shared
        let plain = servers.first(where: Validator.isIP) ?? fallbackServer
        var entries: [Any] = servers

        // A DoH server addressed by hostname needs a plain resolver to bootstrap its TLS host,
        // and DoH through the proxy needs one to fall back on when the proxy is down.
        let needsBootstrap = servers.contains { server in
            guard let host = Validator.dohHost(server) else { return false }
            return !Validator.isIP(host)
        }
        if (needsBootstrap || viaProxy) && !servers.contains(where: Validator.isIP) {
            entries.append(plain)
        }

        let proxyHosts = Set(app.proxies.map(\.address).filter { !Validator.isIP($0) })
        if viaProxy && !proxyHosts.isEmpty {
            let domains = proxyHosts.sorted().map { "full:\($0)" }
            entries.insert(["address": plain, "domains": domains, "skipFallback": true], at: 0)
        }

        var dns: [String: Any] = ["tag": internalTag, "servers": entries]
        if !app.hosts.isEmpty {
            var hostMap: [String: String] = [:]
            for host in app.hosts { hostMap[host.domain] = host.address }
            dns["hosts"] = hostMap
        }

        return dns
    }

    // "direct" is first so it is the default outbound: plain UDP queries the built-in DNS client
    // makes egress through freedom. With a proxy selected, its DoH (TCP) queries go through the
    // main Xray's SOCKS inbound instead; https+local:// always dials directly, bypassing routing.
    private static func buildOutbounds(viaProxy: Bool) -> [[String: Any]] {
        var outbounds: [[String: Any]] = [
            ["tag": "direct", "protocol": "freedom"],
            ["tag": "dns-out", "protocol": "dns"],
        ]

        if viaProxy {
            outbounds.append([
                "tag": "proxy",
                "protocol": "socks",
                "settings": [
                    "servers": [["address": "127.0.0.1", "port": AppConfig.shared.socksPort]]
                ],
            ])
        }

        return outbounds
    }

    private static func buildRouting(viaProxy: Bool) -> [String: Any] {
        var rules: [[String: Any]] = [
            ["type": "field", "inboundTag": ["dns-in"], "outboundTag": "dns-out"]
        ]

        if viaProxy {
            rules.append([
                "type": "field",
                "inboundTag": [internalTag],
                "network": "tcp",
                "outboundTag": "proxy",
            ])
        }

        return ["rules": rules]
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
