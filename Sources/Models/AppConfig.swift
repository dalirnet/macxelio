import Foundation

class AppConfig: ObservableObject {
    static let shared = AppConfig()

    static let apiPort = 23400
    static let testPort = 23450
    static let defaultHTTPPort = 3128
    static let defaultSOCKSPort = 1080

    private static let dateFormatter = ISO8601DateFormatter()

    private let configPath = Tools.url("config.json")
    private let settingsPath = Tools.url("settings.json")
    private var isLoading = false

    @Published var allowLAN: Bool = false { didSet { saveAndNotify() } }
    @Published var httpPort: Int = AppConfig.defaultHTTPPort { didSet { portsChanged() } }
    @Published var socksPort: Int = AppConfig.defaultSOCKSPort { didSet { portsChanged() } }
    @Published var testServer: String = TestServer.google.rawValue { didSet { saveAndNotify() } }
    @Published var systemProxyEnabled: Bool = false { didSet { saveAndNotify() } }
    @Published var dnsServerEnabled: Bool = false { didSet { saveAndNotify() } }
    @Published var proxyMode: ProxyMode = .global { didSet { saveAndNotify() } }
    @Published var selectedProxyId: UUID? { didSet { saveAndNotify() } }

    enum ProxyMode: String, Codable, CaseIterable {
        case global = "Global"
        case rule = "Rule"
        case direct = "Direct"
    }

    @Published var proxies: [Proxy] = [] { didSet { saveAndNotify() } }

    @Published var rules: [Rule] = [] { didSet { saveAndNotify() } }

    @Published var primaryDNS: String = "" { didSet { saveAndNotify() } }
    @Published var secondaryDNS: String = "" { didSet { saveAndNotify() } }
    @Published var hosts: [Host] = [] { didSet { saveAndNotify() } }

    var dnsServerList: [String] {
        [primaryDNS, secondaryDNS].filter { !$0.isEmpty }
    }

    init() {
        load()
    }

    private func saveAndNotify() {
        guard !isLoading else { return }
        if save() {
            NotificationCenter.default.post(name: .configDidChange, object: nil)
        }
    }

    private func portsChanged() {
        saveAndNotify()
        if !isLoading && systemProxyEnabled {
            SystemProxy.apply(true)
        }
    }

    func addProxy(_ proxy: Proxy) {
        proxies.append(proxy)
    }

    func updateProxy(_ proxy: Proxy) {
        if let index = proxies.firstIndex(where: { $0.id == proxy.id }) {
            proxies[index] = proxy
        }
    }

    func deleteProxy(_ proxy: Proxy) {
        proxies.removeAll { $0.id == proxy.id }
        if selectedProxyId == proxy.id {
            selectedProxyId = nil
        }
    }

    func addRule(_ rule: Rule) {
        rules.append(rule)
    }

    func updateRule(_ rule: Rule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        }
    }

    func deleteRule(_ rule: Rule) {
        rules.removeAll { $0.id == rule.id }
    }

    func addHost(_ host: Host) {
        hosts.append(host)
    }

    func updateHost(_ host: Host) {
        if let index = hosts.firstIndex(where: { $0.id == host.id }) {
            hosts[index] = host
        }
    }

    func deleteHost(_ host: Host) {
        hosts.removeAll { $0.id == host.id }
    }

    @discardableResult
    func save() -> Bool {
        var configData: [String: Any] = [:]

        configData["log"] = [
            "loglevel": "error",
            "access": Tools.url("access.log").path,
            "error": Tools.url("xray.log").path,
        ]
        configData["stats"] = [:]
        configData["api"] = ["tag": "api", "services": ["StatsService"]]
        configData["policy"] = [
            "system": [
                "statsOutboundUplink": true,
                "statsOutboundDownlink": true,
            ]
        ]
        configData["inbounds"] = buildInbounds()
        configData["outbounds"] = buildOutbounds()
        configData["routing"] = buildRouting()

        if dnsServerEnabled {
            SystemDNS.writeConfig()
        }

        var settingsData: [String: Any] = [
            "allowLAN": allowLAN,
            "systemProxyEnabled": systemProxyEnabled,
            "dnsServerEnabled": dnsServerEnabled,
            "proxyMode": proxyMode.rawValue,
        ]

        if let selectedId = selectedProxyId {
            settingsData["selectedProxyId"] = selectedId.uuidString
        }

        settingsData["proxies"] = proxies.map { proxyToDict($0) }
        settingsData["rules"] = rules.map { ruleToDict($0) }
        settingsData["httpPort"] = httpPort
        settingsData["socksPort"] = socksPort
        settingsData["primaryDNS"] = primaryDNS
        settingsData["secondaryDNS"] = secondaryDNS
        settingsData["testServer"] = testServer
        settingsData["hosts"] = hosts.map { hostToDict($0) }

        let configChanged = writeJSONIfChanged(configData, to: configPath)
        writeJSONIfChanged(settingsData, to: settingsPath)
        return configChanged
    }

    @discardableResult
    private func writeJSONIfChanged(_ object: [String: Any], to url: URL) -> Bool {
        guard
            let data = try? JSONSerialization.data(
                withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        else { return false }
        if (try? Data(contentsOf: url)) == data { return false }
        try? data.write(to: url)
        return true
    }

    private func loadSettings() -> [String: Any]? {
        guard let data = try? Data(contentsOf: settingsPath),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json
    }

    func load() {
        isLoading = true
        defer { isLoading = false }

        guard let settings = loadSettings() else { return }

        if let lan = settings["allowLAN"] as? Bool { allowLAN = lan }
        if let port = settings["httpPort"] as? Int { httpPort = port }
        if let port = settings["socksPort"] as? Int { socksPort = port }
        if let server = settings["testServer"] as? String, TestServer(rawValue: server) != nil {
            testServer = server
        }
        if let system = settings["systemProxyEnabled"] as? Bool { systemProxyEnabled = system }
        if let dns = settings["dnsServerEnabled"] as? Bool { dnsServerEnabled = dns }
        if let modeStr = settings["proxyMode"] as? String, let mode = ProxyMode(rawValue: modeStr) {
            proxyMode = mode
        }
        if let idStr = settings["selectedProxyId"] as? String {
            selectedProxyId = UUID(uuidString: idStr)
        }

        if let proxiesData = settings["proxies"] as? [[String: Any]] {
            proxies = proxiesData.compactMap { dictToProxy($0) }
        }

        if let rulesData = settings["rules"] as? [[String: Any]] {
            rules = rulesData.compactMap { dictToRule($0) }
        }

        if let primary = settings["primaryDNS"] as? String { primaryDNS = primary }
        if let secondary = settings["secondaryDNS"] as? String { secondaryDNS = secondary }

        if let hostsData = settings["hosts"] as? [[String: Any]] {
            hosts = hostsData.compactMap { dictToHost($0) }
        }
    }

    private var udpSupported: Bool {
        guard proxyMode != .direct, let selectedId = selectedProxyId else { return true }
        guard let proxy = proxies.first(where: { $0.id == selectedId }) else { return true }
        return proxy.type.supportsUDP
    }

    private static func probeTag(_ index: Int) -> String { "probe-\(index)" }

    private static func probePort(_ index: Int) -> Int { testPort + 1 + index }

    func probePort(for proxy: Proxy) -> Int? {
        guard let index = proxies.firstIndex(where: { $0.id == proxy.id }) else { return nil }
        return AppConfig.probePort(index)
    }

    private func buildInbounds() -> [[String: Any]] {
        let listen = allowLAN ? "0.0.0.0" : "127.0.0.1"
        let sniffing: [String: Any] = [
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
        ]

        var inbounds: [[String: Any]] = [
            [
                "tag": "socks-inbound",
                "port": socksPort,
                "listen": listen,
                "protocol": "socks",
                "settings": [
                    "auth": "noauth",
                    "udp": udpSupported,
                    "ip": listen,
                ],
                "sniffing": sniffing,
            ],
            [
                "tag": "http-inbound",
                "port": httpPort,
                "listen": listen,
                "protocol": "http",
                "settings": [:],
                "sniffing": sniffing,
            ],
            [
                "tag": "api",
                "port": AppConfig.apiPort,
                "listen": "127.0.0.1",
                "protocol": "dokodemo-door",
                "settings": ["address": "127.0.0.1"],
            ],
            [
                "tag": "test",
                "port": AppConfig.testPort,
                "listen": "127.0.0.1",
                "protocol": "http",
                "settings": [:],
            ],
        ]

        for index in proxies.indices {
            inbounds.append([
                "tag": Self.probeTag(index),
                "port": Self.probePort(index),
                "listen": "127.0.0.1",
                "protocol": "http",
                "settings": [:],
            ])
        }

        return inbounds
    }

    private func buildOutbounds() -> [[String: Any]] {
        var outbounds: [[String: Any]] = []

        if let selectedId = selectedProxyId,
            let proxy = proxies.first(where: { $0.id == selectedId })
        {
            outbounds.append(buildProxyOutbound(proxy: proxy, tag: "proxy"))
        }

        for (index, proxy) in proxies.enumerated() {
            outbounds.append(buildProxyOutbound(proxy: proxy, tag: Self.probeTag(index)))
        }

        outbounds.append([
            "tag": "direct",
            "protocol": "freedom",
            "settings": [:],
        ])
        outbounds.append([
            "tag": "blocked",
            "protocol": "blackhole",
            "settings": [:],
        ])

        return outbounds
    }

    private func buildProxyOutbound(proxy: Proxy, tag: String) -> [String: Any] {
        var proxyOutbound: [String: Any] = [
            "tag": tag,
            "protocol": proxy.type.rawValue.lowercased(),
        ]

        var serverSettings: [String: Any] = [:]

        switch proxy.type {
        case .vless:
            var user: [String: Any] = [
                "id": proxy.uuid ?? "",
                "encryption": "none",
            ]
            if let flow = proxy.flow, !flow.isEmpty, proxy.security != .none {
                user["flow"] = flow
            }
            serverSettings["vnext"] = [
                [
                    "address": proxy.address,
                    "port": proxy.port,
                    "users": [user],
                ]
            ]
        case .vmess:
            serverSettings["vnext"] = [
                [
                    "address": proxy.address,
                    "port": proxy.port,
                    "users": [
                        [
                            "id": proxy.uuid ?? "",
                            "alterId": 0,
                            "security": "auto",
                        ]
                    ],
                ]
            ]
        case .trojan:
            serverSettings["servers"] = [
                [
                    "address": proxy.address,
                    "port": proxy.port,
                    "password": proxy.password ?? "",
                ]
            ]
        case .shadowsocks:
            serverSettings["servers"] = [
                [
                    "address": proxy.address,
                    "port": proxy.port,
                    "method": proxy.method ?? "aes-256-gcm",
                    "password": proxy.password ?? "",
                ]
            ]
        case .socks:
            var server: [String: Any] = [
                "address": proxy.address,
                "port": proxy.port,
            ]
            if let username = proxy.username, !username.isEmpty,
                let password = proxy.password, !password.isEmpty
            {
                server["users"] = [
                    [
                        "user": username,
                        "pass": password,
                    ]
                ]
            }
            serverSettings["servers"] = [server]
        case .http:
            var server: [String: Any] = [
                "address": proxy.address,
                "port": proxy.port,
            ]
            if let username = proxy.username, !username.isEmpty,
                let password = proxy.password, !password.isEmpty
            {
                server["users"] = [
                    [
                        "user": username,
                        "pass": password,
                    ]
                ]
            }
            serverSettings["servers"] = [server]
        }

        proxyOutbound["settings"] = serverSettings

        if let streamSettings = buildStreamSettings(proxy: proxy) {
            proxyOutbound["streamSettings"] = streamSettings
        }

        if proxy.type.supportsUDP {
            proxyOutbound["mux"] = [
                "enabled": false,
                "concurrency": -1,
                "xudpConcurrency": 16,
                "xudpProxyUDP443": "allow",
            ]
        }

        return proxyOutbound
    }

    private func buildStreamSettings(proxy: Proxy) -> [String: Any]? {
        guard proxy.type.supportsSecurity, proxy.security != .none else { return nil }

        let sni = proxy.sni ?? ""
        let fingerprint = proxy.fingerprint ?? ""

        var settings: [String: Any] = [
            "serverName": sni.isEmpty ? proxy.address : sni,
            "fingerprint": fingerprint.isEmpty ? Proxy.defaultFingerprint : fingerprint,
        ]

        let isReality = proxy.security == .reality
        if isReality {
            settings["publicKey"] = proxy.publicKey ?? ""
            if let shortId = proxy.shortId, !shortId.isEmpty { settings["shortId"] = shortId }
            if let spiderX = proxy.spiderX, !spiderX.isEmpty { settings["spiderX"] = spiderX }
        } else {
            settings["allowInsecure"] = false
        }

        return [
            "network": "tcp",
            "security": proxy.security.value,
            isReality ? "realitySettings" : "tlsSettings": settings,
        ]
    }

    private func buildRouting() -> [String: Any] {
        var routingRules: [[String: Any]] = [
            ["type": "field", "inboundTag": ["api"], "outboundTag": "api"]
        ]

        if selectedProxyId != nil {
            routingRules.append([
                "type": "field", "inboundTag": ["test"], "outboundTag": "proxy",
            ])
        }

        for index in proxies.indices {
            routingRules.append([
                "type": "field",
                "inboundTag": [Self.probeTag(index)],
                "outboundTag": Self.probeTag(index),
            ])
        }

        if proxyMode == .rule {
            for rule in rules {
                var routingRule: [String: Any] = ["type": "field"]

                switch rule.type {
                case .domain, .geosite:
                    routingRule["domain"] = [rule.routingPattern]
                case .ip, .geoip:
                    routingRule["ip"] = [rule.routingPattern]
                }

                switch rule.action {
                case .proxy: routingRule["outboundTag"] = "proxy"
                case .direct: routingRule["outboundTag"] = "direct"
                case .block: routingRule["outboundTag"] = "blocked"
                }

                routingRules.append(routingRule)
            }
        }

        let defaultTag = (proxyMode != .direct && selectedProxyId != nil) ? "proxy" : "direct"
        routingRules.append([
            "type": "field", "network": "tcp,udp", "outboundTag": defaultTag,
        ])

        return [
            "domainStrategy": "IPIfNonMatch",
            "rules": routingRules,
        ]
    }

    private func proxyToDict(_ proxy: Proxy) -> [String: Any] {
        var dict: [String: Any] = [
            "id": proxy.id.uuidString,
            "name": proxy.name,
            "type": proxy.type.rawValue,
            "address": proxy.address,
            "port": proxy.port,
            "createdAt": Self.dateFormatter.string(from: proxy.createdAt),
        ]
        if proxy.security != .none { dict["security"] = proxy.security.rawValue }

        let optional: [String: String?] = [
            "uuid": proxy.uuid,
            "password": proxy.password,
            "method": proxy.method,
            "username": proxy.username,
            "sni": proxy.sni,
            "fingerprint": proxy.fingerprint,
            "flow": proxy.flow,
            "publicKey": proxy.publicKey,
            "shortId": proxy.shortId,
            "spiderX": proxy.spiderX,
        ]
        for (key, value) in optional {
            if let value = value { dict[key] = value }
        }

        return dict
    }

    private func dictToProxy(_ dict: [String: Any]) -> Proxy? {
        guard let idStr = dict["id"] as? String, let id = UUID(uuidString: idStr),
            let name = dict["name"] as? String,
            let typeStr = dict["type"] as? String, let type = Proxy.ProxyType(rawValue: typeStr),
            let address = dict["address"] as? String,
            let port = dict["port"] as? Int
        else { return nil }

        var proxy = Proxy(name: name, type: type, address: address, port: port)
        proxy.id = id
        proxy.uuid = dict["uuid"] as? String
        proxy.password = dict["password"] as? String
        proxy.method = dict["method"] as? String
        proxy.username = dict["username"] as? String
        if let raw = dict["security"] as? String, let security = Proxy.Security(rawValue: raw) {
            proxy.security = security
        }
        proxy.sni = dict["sni"] as? String
        proxy.fingerprint = dict["fingerprint"] as? String
        proxy.flow = dict["flow"] as? String
        proxy.publicKey = dict["publicKey"] as? String
        proxy.shortId = dict["shortId"] as? String
        proxy.spiderX = dict["spiderX"] as? String
        if let dateStr = dict["createdAt"] as? String,
            let date = Self.dateFormatter.date(from: dateStr)
        {
            proxy.createdAt = date
        }
        return proxy
    }

    private func ruleToDict(_ rule: Rule) -> [String: Any] {
        return [
            "id": rule.id.uuidString,
            "type": rule.type.rawValue,
            "pattern": rule.pattern,
            "action": rule.action.rawValue,
            "createdAt": Self.dateFormatter.string(from: rule.createdAt),
        ]
    }

    private func dictToRule(_ dict: [String: Any]) -> Rule? {
        guard let idStr = dict["id"] as? String, let id = UUID(uuidString: idStr),
            let typeStr = dict["type"] as? String, let type = Rule.RuleType(rawValue: typeStr),
            let pattern = dict["pattern"] as? String,
            let actionStr = dict["action"] as? String,
            let action = Rule.RuleAction(rawValue: actionStr)
        else { return nil }

        var rule = Rule(type: type, pattern: pattern, action: action)
        rule.id = id
        if let dateStr = dict["createdAt"] as? String,
            let date = Self.dateFormatter.date(from: dateStr)
        {
            rule.createdAt = date
        }
        return rule
    }

    private func hostToDict(_ host: Host) -> [String: Any] {
        return [
            "id": host.id.uuidString,
            "domain": host.domain,
            "address": host.address,
            "createdAt": Self.dateFormatter.string(from: host.createdAt),
        ]
    }

    private func dictToHost(_ dict: [String: Any]) -> Host? {
        guard let idStr = dict["id"] as? String, let id = UUID(uuidString: idStr),
            let domain = dict["domain"] as? String,
            let address = dict["address"] as? String
        else { return nil }

        var host = Host(domain: domain, address: address)
        host.id = id
        if let dateStr = dict["createdAt"] as? String,
            let date = Self.dateFormatter.date(from: dateStr)
        {
            host.createdAt = date
        }
        return host
    }
}

extension Notification.Name {
    static let configDidChange = Notification.Name("configDidChange")
}
