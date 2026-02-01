import Foundation

/// Unified configuration manager
/// All data stored in ~/.config/macxelio/config.json
class AppConfig: ObservableObject {
    static let shared = AppConfig()

    private let configDir: URL
    private let configPath: URL
    private var isLoading = false

    // MARK: - App Settings

    @Published var socksPort: Int = 10808 { didSet { saveAndNotify() } }
    @Published var httpPort: Int = 10809 { didSet { saveAndNotify() } }
    @Published var autoConnect: Bool = false { didSet { saveAndNotify() } }
    @Published var allowLAN: Bool = false { didSet { saveAndNotify() } }
    @Published var systemProxyEnabled: Bool = false { didSet { saveAndNotify() } }
    @Published var dnsServerEnabled: Bool = false { didSet { saveAndNotify() } }
    @Published var proxyMode: ProxyMode = .global { didSet { saveAndNotify() } }
    @Published var selectedConfigId: UUID? { didSet { saveAndNotify() } }

    enum ProxyMode: String, Codable, CaseIterable {
        case global = "Global"
        case rule = "Rule"
        case direct = "Direct"

        var abbreviation: String {
            switch self {
            case .global: return "GLB"
            case .rule: return "RUL"
            case .direct: return "DIR"
            }
        }
    }

    // MARK: - Proxy Configs (outbound servers)

    @Published var configs: [Config] = [] { didSet { saveAndNotify() } }

    // MARK: - Rules

    @Published var rules: [Rule] = [] { didSet { saveAndNotify() } }

    // MARK: - DNS

    @Published var dnsServers: [DNSServer] = [] { didSet { saveAndNotify() } }
    @Published var dnsPolicies: [DNSPolicy] = [] { didSet { saveAndNotify() } }

    // MARK: - Initialization

    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        configDir = homeDir.appendingPathComponent(".config/macxelio")
        configPath = configDir.appendingPathComponent("config.json")

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        load()
    }

    // MARK: - Save and Notify

    private func saveAndNotify() {
        guard !isLoading else { return }
        save()
        NotificationCenter.default.post(name: .configDidChange, object: nil)
    }

    // MARK: - Config CRUD

    func addConfig(_ config: Config) {
        configs.append(config)
    }

    func updateConfig(_ config: Config) {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        }
    }

    func deleteConfig(_ config: Config) {
        configs.removeAll { $0.id == config.id }
        if selectedConfigId == config.id {
            selectedConfigId = nil
        }
    }

    func getConfig(by id: UUID) -> Config? {
        configs.first { $0.id == id }
    }

    // MARK: - Rule CRUD

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

    func clearRules() {
        rules.removeAll()
    }

    // MARK: - DNS CRUD

    func addDNSServer(_ server: DNSServer) {
        dnsServers.append(server)
    }

    func updateDNSServer(_ server: DNSServer) {
        if let index = dnsServers.firstIndex(where: { $0.id == server.id }) {
            dnsServers[index] = server
        }
    }

    func deleteDNSServer(_ server: DNSServer) {
        dnsServers.removeAll { $0.id == server.id }
    }

    func addDNSPolicy(_ policy: DNSPolicy) {
        dnsPolicies.append(policy)
    }

    func updateDNSPolicy(_ policy: DNSPolicy) {
        if let index = dnsPolicies.firstIndex(where: { $0.id == policy.id }) {
            dnsPolicies[index] = policy
        }
    }

    func deleteDNSPolicy(_ policy: DNSPolicy) {
        dnsPolicies.removeAll { $0.id == policy.id }
    }

    func clearDNS() {
        dnsServers.removeAll()
        dnsPolicies.removeAll()
    }

    // MARK: - Persistence

    func save() {
        var configData: [String: Any] = [:]

        // Standard xray config sections
        configData["log"] = ["loglevel": "warning"]
        configData["inbounds"] = buildInbounds()
        configData["outbounds"] = buildOutbounds()

        if proxyMode == .rule && !rules.isEmpty {
            configData["routing"] = buildRouting()
        }

        if dnsServerEnabled && (!dnsServers.isEmpty || !dnsPolicies.isEmpty) {
            configData["dns"] = buildDNS()
        }

        // Custom macxelio settings
        var macxelioSettings: [String: Any] = [
            "socksPort": socksPort,
            "httpPort": httpPort,
            "autoConnect": autoConnect,
            "allowLAN": allowLAN,
            "systemProxyEnabled": systemProxyEnabled,
            "dnsServerEnabled": dnsServerEnabled,
            "proxyMode": proxyMode.rawValue,
        ]

        if let selectedId = selectedConfigId {
            macxelioSettings["selectedConfigId"] = selectedId.uuidString
        }

        macxelioSettings["configs"] = configs.map { configToDict($0) }
        macxelioSettings["rules"] = rules.map { ruleToDict($0) }
        macxelioSettings["dnsServers"] = dnsServers.map { dnsServerToDict($0) }
        macxelioSettings["dnsPolicies"] = dnsPolicies.map { dnsPolicyToDict($0) }

        configData["_macxelio"] = macxelioSettings

        if let jsonData = try? JSONSerialization.data(
            withJSONObject: configData, options: [.prettyPrinted, .sortedKeys])
        {
            try? jsonData.write(to: configPath)
        }
    }

    func load() {
        isLoading = true
        defer { isLoading = false }

        guard FileManager.default.fileExists(atPath: configPath.path),
            let data = try? Data(contentsOf: configPath),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let macxelio = json["_macxelio"] as? [String: Any]
        else {
            return
        }

        if let port = macxelio["socksPort"] as? Int { socksPort = port }
        if let port = macxelio["httpPort"] as? Int { httpPort = port }
        if let auto = macxelio["autoConnect"] as? Bool { autoConnect = auto }
        if let lan = macxelio["allowLAN"] as? Bool { allowLAN = lan }
        if let system = macxelio["systemProxyEnabled"] as? Bool { systemProxyEnabled = system }
        if let dns = macxelio["dnsServerEnabled"] as? Bool { dnsServerEnabled = dns }
        if let modeStr = macxelio["proxyMode"] as? String, let mode = ProxyMode(rawValue: modeStr) {
            proxyMode = mode
        }
        if let idStr = macxelio["selectedConfigId"] as? String {
            selectedConfigId = UUID(uuidString: idStr)
        }

        if let configsData = macxelio["configs"] as? [[String: Any]] {
            configs = configsData.compactMap { dictToConfig($0) }
        }

        if let rulesData = macxelio["rules"] as? [[String: Any]] {
            rules = rulesData.compactMap { dictToRule($0) }
        }

        if let serversData = macxelio["dnsServers"] as? [[String: Any]] {
            dnsServers = serversData.compactMap { dictToDNSServer($0) }
        }

        if let policiesData = macxelio["dnsPolicies"] as? [[String: Any]] {
            dnsPolicies = policiesData.compactMap { dictToDNSPolicy($0) }
        }
    }

    func getConfigPath() -> String {
        configPath.path
    }

    func getConfigDir() -> URL {
        configDir
    }

    // MARK: - Xray Config Building

    private func buildInbounds() -> [[String: Any]] {
        let listen = allowLAN ? "0.0.0.0" : "127.0.0.1"

        return [
            [
                "tag": "socks-inbound",
                "port": socksPort,
                "listen": listen,
                "protocol": "socks",
                "settings": [
                    "auth": "noauth",
                    "udp": true,
                    "ip": listen,
                ],
                "sniffing": [
                    "enabled": true,
                    "destOverride": ["http", "tls"],
                ],
            ],
            [
                "tag": "http-inbound",
                "port": httpPort,
                "listen": listen,
                "protocol": "http",
                "settings": [:],
            ],
        ]
    }

    private func buildOutbounds() -> [[String: Any]] {
        var outbounds: [[String: Any]] = []

        if let selectedId = selectedConfigId,
            let config = configs.first(where: { $0.id == selectedId })
        {
            outbounds.append(buildProxyOutbound(config: config))
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

    private func buildProxyOutbound(config: Config) -> [String: Any] {
        var proxyOutbound: [String: Any] = [
            "tag": "proxy",
            "protocol": config.type.rawValue.lowercased(),
        ]

        var serverSettings: [String: Any] = [:]
        let streamSettings: [String: Any] = [:]

        switch config.type {
        case .vless:
            serverSettings["vnext"] = [
                [
                    "address": config.address,
                    "port": config.port,
                    "users": [
                        [
                            "id": config.uuid ?? "",
                            "encryption": "none",
                        ]
                    ],
                ]
            ]
        case .vmess:
            serverSettings["vnext"] = [
                [
                    "address": config.address,
                    "port": config.port,
                    "users": [
                        [
                            "id": config.uuid ?? "",
                            "alterId": 0,
                            "security": "auto",
                        ]
                    ],
                ]
            ]
        case .trojan:
            serverSettings["servers"] = [
                [
                    "address": config.address,
                    "port": config.port,
                    "password": config.password ?? "",
                ]
            ]
        case .shadowsocks:
            serverSettings["servers"] = [
                [
                    "address": config.address,
                    "port": config.port,
                    "method": config.method ?? "aes-256-gcm",
                    "password": config.password ?? "",
                ]
            ]
        case .socks:
            var server: [String: Any] = [
                "address": config.address,
                "port": config.port,
            ]
            if let username = config.username, !username.isEmpty,
                let password = config.password, !password.isEmpty
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
                "address": config.address,
                "port": config.port,
            ]
            if let username = config.username, !username.isEmpty,
                let password = config.password, !password.isEmpty
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
        if !streamSettings.isEmpty {
            proxyOutbound["streamSettings"] = streamSettings
        }

        return proxyOutbound
    }

    private func buildRouting() -> [String: Any] {
        var routingRules: [[String: Any]] = []

        for rule in rules {
            var routingRule: [String: Any] = ["type": "field"]

            switch rule.type {
            case .domain, .geosite:
                routingRule["domain"] = [rule.pattern]
            case .ip, .geoip:
                routingRule["ip"] = [rule.pattern]
            }

            switch rule.action {
            case .proxy: routingRule["outboundTag"] = "proxy"
            case .direct: routingRule["outboundTag"] = "direct"
            case .block: routingRule["outboundTag"] = "blocked"
            }

            routingRules.append(routingRule)
        }

        return [
            "domainStrategy": "IPIfNonMatch",
            "rules": routingRules,
        ]
    }

    private func buildDNS() -> [String: Any] {
        var dnsConfig: [String: Any] = [:]

        if !dnsServers.isEmpty {
            dnsConfig["servers"] = dnsServers.map { $0.address }
        }

        if !dnsPolicies.isEmpty {
            var hosts: [String: String] = [:]
            for policy in dnsPolicies {
                hosts[policy.domain] = policy.dnsServer
            }
            dnsConfig["hosts"] = hosts
        }

        return dnsConfig
    }

    // MARK: - Serialization Helpers

    private func configToDict(_ config: Config) -> [String: Any] {
        var dict: [String: Any] = [
            "id": config.id.uuidString,
            "name": config.name,
            "type": config.type.rawValue,
            "address": config.address,
            "port": config.port,
            "createdAt": ISO8601DateFormatter().string(from: config.createdAt),
        ]
        if let uuid = config.uuid { dict["uuid"] = uuid }
        if let password = config.password { dict["password"] = password }
        if let method = config.method { dict["method"] = method }
        if let username = config.username { dict["username"] = username }
        if let ping = config.ping { dict["ping"] = ping }
        return dict
    }

    private func dictToConfig(_ dict: [String: Any]) -> Config? {
        guard let idStr = dict["id"] as? String, let id = UUID(uuidString: idStr),
            let name = dict["name"] as? String,
            let typeStr = dict["type"] as? String, let type = Config.ConfigType(rawValue: typeStr),
            let address = dict["address"] as? String,
            let port = dict["port"] as? Int
        else { return nil }

        var config = Config(name: name, type: type, address: address, port: port)
        config.id = id
        config.uuid = dict["uuid"] as? String
        config.password = dict["password"] as? String
        config.method = dict["method"] as? String
        config.username = dict["username"] as? String
        config.ping = dict["ping"] as? Int
        if let dateStr = dict["createdAt"] as? String,
            let date = ISO8601DateFormatter().date(from: dateStr)
        {
            config.createdAt = date
        }
        return config
    }

    private func ruleToDict(_ rule: Rule) -> [String: Any] {
        return [
            "id": rule.id.uuidString,
            "type": rule.type.rawValue,
            "pattern": rule.pattern,
            "action": rule.action.rawValue,
            "createdAt": ISO8601DateFormatter().string(from: rule.createdAt),
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
            let date = ISO8601DateFormatter().date(from: dateStr)
        {
            rule.createdAt = date
        }
        return rule
    }

    private func dnsServerToDict(_ server: DNSServer) -> [String: Any] {
        return [
            "id": server.id.uuidString,
            "address": server.address,
            "createdAt": ISO8601DateFormatter().string(from: server.createdAt),
        ]
    }

    private func dictToDNSServer(_ dict: [String: Any]) -> DNSServer? {
        guard let idStr = dict["id"] as? String, let id = UUID(uuidString: idStr),
            let address = dict["address"] as? String
        else { return nil }

        var server = DNSServer(address: address)
        server.id = id
        if let dateStr = dict["createdAt"] as? String,
            let date = ISO8601DateFormatter().date(from: dateStr)
        {
            server.createdAt = date
        }
        return server
    }

    private func dnsPolicyToDict(_ policy: DNSPolicy) -> [String: Any] {
        return [
            "id": policy.id.uuidString,
            "domain": policy.domain,
            "dnsServer": policy.dnsServer,
            "createdAt": ISO8601DateFormatter().string(from: policy.createdAt),
        ]
    }

    private func dictToDNSPolicy(_ dict: [String: Any]) -> DNSPolicy? {
        guard let idStr = dict["id"] as? String, let id = UUID(uuidString: idStr),
            let domain = dict["domain"] as? String,
            let dnsServer = dict["dnsServer"] as? String
        else { return nil }

        var policy = DNSPolicy(domain: domain, dnsServer: dnsServer)
        policy.id = id
        if let dateStr = dict["createdAt"] as? String,
            let date = ISO8601DateFormatter().date(from: dateStr)
        {
            policy.createdAt = date
        }
        return policy
    }
}

extension Notification.Name {
    static let configDidChange = Notification.Name("configDidChange")
}
