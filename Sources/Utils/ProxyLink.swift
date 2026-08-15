import Foundation

enum ProxyLink {
    enum Outcome {
        case proxy(Proxy)
        case failure(String)
    }

    static func parse(_ text: String) -> Outcome {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let separator = trimmed.range(of: "://") else {
            return .failure("Paste a share link, e.g. vless://…")
        }

        switch trimmed[..<separator.lowerBound].lowercased() {
        case "vless": return parseVLESS(trimmed)
        case "trojan": return parseTrojan(trimmed)
        case "vmess": return parseVMess(trimmed)
        case "ss": return parseShadowsocks(trimmed)
        case "socks", "socks5": return parseSimple(trimmed, type: .socks)
        case "http", "https": return parseSimple(trimmed, type: .http)
        case let scheme: return .failure("“\(scheme)” links are not supported.")
        }
    }

    private static func parseVLESS(_ link: String) -> Outcome {
        let (base, tag) = split(link)
        guard let url = URLComponents(string: base), let host = url.host, let port = url.port,
            let uuid = url.user, !uuid.isEmpty
        else { return .failure("Not a valid VLESS link.") }

        let params = query(url)
        if let unsupported = transportError(params["type"]) { return .failure(unsupported) }

        var proxy = Proxy(name: tag.isEmpty ? host : tag, type: .vless, address: host, port: port)
        proxy.uuid = uuid
        applySecurity(to: &proxy, params: params, fallback: .none)
        if proxy.security != .none, let flow = params["flow"], !flow.isEmpty {
            proxy.flow = flow
        }
        return .proxy(proxy)
    }

    private static func parseTrojan(_ link: String) -> Outcome {
        let (base, tag) = split(link)
        guard let url = URLComponents(string: base), let host = url.host, let port = url.port,
            let password = url.user, !password.isEmpty
        else { return .failure("Not a valid Trojan link.") }

        let params = query(url)
        if let unsupported = transportError(params["type"]) { return .failure(unsupported) }

        var proxy = Proxy(name: tag.isEmpty ? host : tag, type: .trojan, address: host, port: port)
        proxy.password = password.removingPercentEncoding ?? password
        applySecurity(to: &proxy, params: params, fallback: .tls)
        return .proxy(proxy)
    }

    private static func parseVMess(_ link: String) -> Outcome {
        let encoded = String(link.dropFirst("vmess://".count))
        guard let data = decodeBase64(encoded),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let address = json["add"] as? String, !address.isEmpty
        else { return .failure("Not a valid VMess link.") }

        let network = string(json["net"])
        if let unsupported = transportError(network.isEmpty ? nil : network) {
            return .failure(unsupported)
        }

        let tag = string(json["ps"])
        var proxy = Proxy(
            name: tag.isEmpty ? address : tag,
            type: .vmess,
            address: address,
            port: port(json["port"]) ?? 443
        )
        proxy.uuid = string(json["id"])

        let params = [
            "security": string(json["tls"]),
            "sni": string(json["sni"]),
            "host": string(json["host"]),
            "fp": string(json["fp"]),
        ].filter { !$0.value.isEmpty }
        applySecurity(to: &proxy, params: params, fallback: .none)

        return .proxy(proxy)
    }

    private static func parseShadowsocks(_ link: String) -> Outcome {
        let (base, tag) = split(link)
        var body = String(base.dropFirst("ss://".count))
        if let queryStart = body.firstIndex(of: "?") { body = String(body[..<queryStart]) }

        var credential = ""
        var server = ""

        if let at = body.lastIndex(of: "@") {
            let userinfo = String(body[..<at])
            credential =
                decodeBase64(userinfo).flatMap { String(data: $0, encoding: .utf8) }
                ?? userinfo.removingPercentEncoding ?? userinfo
            server = String(body[body.index(after: at)...])
        } else {
            guard let data = decodeBase64(body), let decoded = String(data: data, encoding: .utf8),
                let at = decoded.lastIndex(of: "@")
            else { return .failure("Not a valid Shadowsocks link.") }
            credential = String(decoded[..<at])
            server = String(decoded[decoded.index(after: at)...])
        }

        let parts = credential.split(separator: ":", maxSplits: 1)
        guard parts.count == 2, let endpoint = hostPort(server) else {
            return .failure("Not a valid Shadowsocks link.")
        }

        let method = String(parts[0]).lowercased()
        guard Proxy.shadowsocksMethods.contains(method) else {
            return .failure("Encryption method “\(method)” is not supported.")
        }

        var proxy = Proxy(
            name: tag.isEmpty ? endpoint.host : tag,
            type: .shadowsocks,
            address: endpoint.host,
            port: endpoint.port
        )
        proxy.method = method
        proxy.password = String(parts[1])
        return .proxy(proxy)
    }

    private static func parseSimple(_ link: String, type: Proxy.ProxyType) -> Outcome {
        let (base, tag) = split(link)
        guard let url = URLComponents(string: base), let host = url.host, let port = url.port
        else { return .failure("Not a valid \(type.rawValue) link.") }

        var proxy = Proxy(name: tag.isEmpty ? host : tag, type: type, address: host, port: port)
        proxy.username = url.user
        proxy.password = url.password
        return .proxy(proxy)
    }

    private static func applySecurity(
        to proxy: inout Proxy, params: [String: String], fallback: Proxy.Security
    ) {
        switch params["security"]?.lowercased() {
        case "reality": proxy.security = .reality
        case "tls", "xtls": proxy.security = .tls
        case "none": proxy.security = .none
        default: proxy.security = fallback
        }

        guard proxy.security != .none else { return }

        proxy.sni = params["sni"] ?? params["peer"] ?? params["host"]
        proxy.fingerprint = params["fp"] ?? Proxy.defaultFingerprint

        if proxy.security == .reality {
            proxy.publicKey = params["pbk"]
            proxy.shortId = params["sid"]
            proxy.spiderX = params["spx"]
        }
    }

    private static func transportError(_ network: String?) -> String? {
        guard let network = network?.lowercased(), !network.isEmpty, network != "tcp",
            network != "raw"
        else { return nil }
        return "Only TCP transport is supported — this link uses “\(network)”."
    }

    private static func split(_ link: String) -> (base: String, tag: String) {
        guard let hash = link.firstIndex(of: "#") else { return (link, "") }
        let tag = String(link[link.index(after: hash)...])
        return (String(link[..<hash]), tag.removingPercentEncoding ?? tag)
    }

    private static func query(_ url: URLComponents) -> [String: String] {
        var params: [String: String] = [:]
        for item in url.queryItems ?? [] {
            if let value = item.value, !value.isEmpty {
                params[item.name.lowercased()] = value
            }
        }
        return params
    }

    private static func hostPort(_ value: String) -> (host: String, port: Int)? {
        guard let colon = value.lastIndex(of: ":"),
            let port = Int(value[value.index(after: colon)...])
        else { return nil }
        let host = String(value[..<colon])
        return host.isEmpty ? nil : (host, port)
    }

    private static func string(_ value: Any?) -> String {
        if let text = value as? String { return text }
        if let number = value as? Int { return String(number) }
        return ""
    }

    private static func port(_ value: Any?) -> Int? {
        if let number = value as? Int { return number }
        if let text = value as? String { return Int(text) }
        return nil
    }

    private static func decodeBase64(_ value: String) -> Data? {
        var normalized =
            value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let remainder = normalized.count % 4
        if remainder > 0 {
            normalized += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: normalized)
    }
}
