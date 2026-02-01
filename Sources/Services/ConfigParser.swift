import Foundation

class ConfigParser {
    func parse(uri: String) -> Config? {
        let trimmed = uri.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("vless://") {
            return parseVLESS(trimmed)
        } else if trimmed.hasPrefix("vmess://") {
            return parseVMess(trimmed)
        } else if trimmed.hasPrefix("trojan://") {
            return parseTrojan(trimmed)
        } else if trimmed.hasPrefix("ss://") {
            return parseShadowsocks(trimmed)
        }

        return nil
    }

    // vless://uuid@host:port?security=tls&sni=xxx#name
    private func parseVLESS(_ uri: String) -> Config? {
        guard let url = URL(string: uri) else { return nil }

        let uuid = url.user ?? ""
        let host = url.host ?? ""
        let port = url.port ?? 443
        let name = url.fragment?.removingPercentEncoding ?? host

        return Config(
            name: name,
            type: .vless,
            address: host,
            port: port,
            uuid: uuid
        )
    }

    // vmess://base64(json)
    private func parseVMess(_ uri: String) -> Config? {
        let base64Part = String(uri.dropFirst(8))
        guard let data = Data(base64Encoded: base64Part),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let name = json["ps"] as? String ?? json["add"] as? String ?? ""
        let host = json["add"] as? String ?? ""
        let port = (json["port"] as? Int) ?? Int(json["port"] as? String ?? "") ?? 443
        let uuid = json["id"] as? String ?? ""

        return Config(
            name: name,
            type: .vmess,
            address: host,
            port: port,
            uuid: uuid
        )
    }

    // trojan://password@host:port?sni=xxx#name
    private func parseTrojan(_ uri: String) -> Config? {
        guard let url = URL(string: uri) else { return nil }

        let password = url.user ?? ""
        let host = url.host ?? ""
        let port = url.port ?? 443
        let name = url.fragment?.removingPercentEncoding ?? host

        return Config(
            name: name,
            type: .trojan,
            address: host,
            port: port,
            password: password
        )
    }

    // ss://base64(method:password)@host:port#name
    private func parseShadowsocks(_ uri: String) -> Config? {
        var working = String(uri.dropFirst(5))

        var name = ""
        if let hashIndex = working.lastIndex(of: "#") {
            name = String(working[working.index(after: hashIndex)...]).removingPercentEncoding ?? ""
            working = String(working[..<hashIndex])
        }

        var host = ""
        var port = 443
        var method = ""
        var password = ""

        if let atIndex = working.lastIndex(of: "@") {
            let credentials = String(working[..<atIndex])
            let hostPort = String(working[working.index(after: atIndex)...])

            if let decoded = Data(base64Encoded: credentials),
                let credString = String(data: decoded, encoding: .utf8),
                let colonIndex = credString.firstIndex(of: ":")
            {
                method = String(credString[..<colonIndex])
                password = String(credString[credString.index(after: colonIndex)...])
            }

            if let colonIndex = hostPort.lastIndex(of: ":") {
                host = String(hostPort[..<colonIndex])
                port = Int(hostPort[hostPort.index(after: colonIndex)...]) ?? 443
            } else {
                host = hostPort
            }
        } else {
            if let decoded = Data(base64Encoded: working),
                let credString = String(data: decoded, encoding: .utf8)
            {
                let parts = credString.components(separatedBy: "@")
                if parts.count == 2 {
                    if let colonIndex = parts[0].firstIndex(of: ":") {
                        method = String(parts[0][..<colonIndex])
                        password = String(parts[0][parts[0].index(after: colonIndex)...])
                    }
                    if let colonIndex = parts[1].lastIndex(of: ":") {
                        host = String(parts[1][..<colonIndex])
                        port = Int(parts[1][parts[1].index(after: colonIndex)...]) ?? 443
                    }
                }
            }
        }

        if name.isEmpty {
            name = host
        }

        return Config(
            name: name,
            type: .shadowsocks,
            address: host,
            port: port,
            password: password,
            method: method
        )
    }
}
