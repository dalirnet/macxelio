import Foundation

enum SystemDNS {
    static let configPath = Tools.dir.appendingPathComponent("dns.json")

    private static let internalTag = "dns-internal"
    private static let fallbackServer = "1.1.1.1"
    private static let defaultServers = [fallbackServer, "8.8.8.8"]

    static var bootstrapServer: String {
        AppConfig.shared.dnsServerList.first(where: Validator.isIP) ?? fallbackServer
    }

    static func point(_ service: String) {
        Shell.run("/usr/sbin/networksetup", ["-setdnsservers", service, "127.0.0.1"])
    }

    static func reset(_ service: String) {
        Shell.run("/usr/sbin/networksetup", ["-setdnsservers", service, "empty"])
    }

    static func writeConfig() {
        guard
            let data = try? JSONSerialization.data(
                withJSONObject: buildConfig(), options: [.prettyPrinted, .sortedKeys])
        else { return }
        if (try? Data(contentsOf: configPath)) != data {
            try? data.write(to: configPath, options: .atomic)
        }
    }

    private static func buildConfig() -> [String: Any] {
        let app = AppConfig.shared
        let servers = app.dnsServerList.isEmpty ? defaultServers : app.dnsServerList
        let viaProxy =
            app.usesProxy
            && (app.tunnelActive || servers.contains { $0.lowercased().hasPrefix("https://") })

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
        let plain = bootstrapServer
        let tunnel = app.tunnelActive
        var entries: [Any] = servers.map { tunnel && Validator.isIP($0) ? "tcp://\($0)" : $0 }

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
            let address = tunnel ? "tcp+local://\(plain)" : plain
            entries.insert(["address": address, "domains": domains, "skipFallback": true], at: 0)
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
}
