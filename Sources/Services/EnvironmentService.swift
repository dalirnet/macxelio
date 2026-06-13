import Foundation

struct ProxyEnvironment: Identifiable {
    enum Category: String, CaseIterable {
        case general = "General"
        case editor = "Editors"
        case packageManager = "Package Managers"
    }

    enum Kind {
        case line((String) -> String)
        case json(key: String)
        case docker
    }

    let id: String
    let name: String
    let category: Category
    let commands: [String]
    let configPath: String
    let kind: Kind
    var appName: String? = nil
}

@MainActor
class EnvironmentService: ObservableObject {
    @Published var available: Set<String> = []
    @Published var enabled: Set<String> = []

    private let dockerConfig = "~/.docker/config.json"

    let environments: [ProxyEnvironment] = [
        ProxyEnvironment(
            id: "git", name: "git",
            category: .general, commands: ["git"],
            configPath: "~/.gitconfig",
            kind: .line { url in "[http]\n\tproxy = \(url)" }
        ),
        ProxyEnvironment(
            id: "docker", name: "docker",
            category: .general, commands: ["docker"],
            configPath: "~/.docker/config.json",
            kind: .docker
        ),
        ProxyEnvironment(
            id: "shell", name: "Shell env",
            category: .general, commands: [],
            configPath: "~/.zshrc",
            kind: .line { url in
                """
                export http_proxy=\(url)
                export https_proxy=\(url)
                export all_proxy=\(url)
                export HTTP_PROXY=\(url)
                export HTTPS_PROXY=\(url)
                export ALL_PROXY=\(url)
                """
            }
        ),
        ProxyEnvironment(
            id: "zed", name: "Zed",
            category: .editor, commands: ["zed"],
            configPath: "~/.config/zed/settings.json",
            kind: .json(key: "proxy"), appName: "Zed"
        ),
        ProxyEnvironment(
            id: "vscode", name: "VS Code",
            category: .editor, commands: ["code"],
            configPath: "~/Library/Application Support/Code/User/settings.json",
            kind: .json(key: "http.proxy"), appName: "Visual Studio Code"
        ),
        ProxyEnvironment(
            id: "cursor", name: "Cursor",
            category: .editor, commands: ["cursor"],
            configPath: "~/Library/Application Support/Cursor/User/settings.json",
            kind: .json(key: "http.proxy"), appName: "Cursor"
        ),
        ProxyEnvironment(
            id: "npm", name: "npm",
            category: .packageManager, commands: ["npm", "pnpm", "yarn"],
            configPath: "~/.npmrc",
            kind: .line { url in "proxy=\(url)\nhttps-proxy=\(url)" }
        ),
        ProxyEnvironment(
            id: "pip", name: "pip",
            category: .packageManager, commands: ["pip", "pip3"],
            configPath: "~/.config/pip/pip.conf",
            kind: .line { url in "[global]\nproxy = \(url)" }
        ),
        ProxyEnvironment(
            id: "conda", name: "conda",
            category: .packageManager, commands: ["conda"],
            configPath: "~/.condarc",
            kind: .line { url in "proxy_servers:\n  http: \(url)\n  https: \(url)" }
        ),
        ProxyEnvironment(
            id: "cargo", name: "cargo",
            category: .packageManager, commands: ["cargo"],
            configPath: "~/.cargo/config.toml",
            kind: .line { url in "[http]\nproxy = \"\(url)\"" }
        ),
        ProxyEnvironment(
            id: "gem", name: "gem",
            category: .packageManager, commands: ["gem"],
            configPath: "~/.gemrc",
            kind: .line { url in "http_proxy: \(url)" }
        ),
        ProxyEnvironment(
            id: "go", name: "go",
            category: .packageManager, commands: ["go"],
            configPath: "~/.config/go/env",
            kind: .line { url in "http_proxy=\(url)\nhttps_proxy=\(url)" }
        ),
    ]

    private var proxyURL: String {
        "http://127.0.0.1:\(AppConfig.shared.httpPort)"
    }

    func refresh() {
        var on: Set<String> = []
        for environment in environments {
            let isOn: Bool
            switch environment.kind {
            case .docker:
                isOn = isDockerEnabled()
            case .json(let key):
                isOn = hasJSONLine(environment.configPath, key: key)
            case .line(let body):
                isOn = hasConfig(environment.configPath, body: body(proxyURL))
            }
            if isOn { on.insert(environment.id) }
        }
        enabled = on

        detectAvailable()
    }

    func setEnabled(_ environment: ProxyEnvironment, _ on: Bool) {
        switch environment.kind {
        case .docker:
            setDockerProxy(on)
        case .json(let key):
            setJSONLine(environment.configPath, key: key, on: on)
        case .line(let body):
            setConfig(environment.configPath, body: body(proxyURL), on: on)
        }

        if on { enabled.insert(environment.id) } else { enabled.remove(environment.id) }
    }

    func isAvailable(_ environment: ProxyEnvironment) -> Bool {
        environment.commands.isEmpty || !available.isDisjoint(with: environment.commands)
    }

    private func detectAvailable() {
        let names = Set(environments.flatMap { $0.commands })
        let apps = environments.compactMap { env in env.appName.map { ($0, env.commands) } }
        Task.detached { [names, apps] in
            let list = names.joined(separator: " ")
            let out = Shell.output(
                "/bin/zsh",
                ["-lc", "for c in \(list); do command -v $c >/dev/null 2>&1 && echo $c; done"])
            var found = Set(out.split(separator: "\n").map(String.init))
            for (app, commands) in apps
            where FileManager.default.fileExists(atPath: "/Applications/\(app).app") {
                found.formUnion(commands)
            }
            let detected = found
            await MainActor.run { self.available = detected }
        }
    }

    private func expand(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }

    private func hasConfig(_ path: String, body: String) -> Bool {
        guard !body.isEmpty,
            let content = try? String(contentsOfFile: expand(path), encoding: .utf8)
        else { return false }
        return content.contains(body)
    }

    private func setConfig(_ path: String, body: String, on: Bool) {
        let full = expand(path)
        var content = (try? String(contentsOfFile: full, encoding: .utf8)) ?? ""
        if let range = content.range(of: body + "\n") ?? content.range(of: body) {
            content.removeSubrange(range)
        }
        if on {
            if !content.isEmpty && !content.hasSuffix("\n") { content += "\n" }
            content += body + "\n"
        }
        write(full, content)
    }

    private func hasJSONLine(_ path: String, key: String) -> Bool {
        guard let content = try? String(contentsOfFile: expand(path), encoding: .utf8)
        else { return false }
        return content.components(separatedBy: "\n").contains { isProxyLine($0, key: key) }
    }

    private func setJSONLine(_ path: String, key: String, on: Bool) {
        let full = expand(path)
        var lines = ((try? String(contentsOfFile: full, encoding: .utf8)) ?? "")
            .components(separatedBy: "\n")
        lines.removeAll { isProxyLine($0, key: key) }
        var content = lines.joined(separator: "\n")

        if on {
            let line = "  \"\(key)\": \"\(proxyURL)\","
            if let brace = content.firstIndex(of: "{") {
                let after = content.index(after: brace)
                let rest = String(content[after...]).trimmingCharacters(in: .whitespacesAndNewlines)
                let suffix = (rest.isEmpty || rest.hasPrefix("}")) ? "\n" : ""
                content.insert(contentsOf: "\n\(line)\(suffix)", at: after)
            } else {
                content = "{\n\(line)\n}\n"
            }
        }
        write(full, content)
    }

    private func isProxyLine(_ line: String, key: String) -> Bool {
        line.contains("\"\(key)\"") && line.contains("127.0.0.1")
    }

    private func write(_ full: String, _ content: String) {
        let dir = (full as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? content.write(toFile: full, atomically: true, encoding: .utf8)
    }

    private func setDockerProxy(_ on: Bool) {
        let full = expand(dockerConfig)
        let dir = (full as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true)

        var json =
            (try? Data(contentsOf: URL(fileURLWithPath: full)))
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]

        if on {
            var proxies = json["proxies"] as? [String: Any] ?? [:]
            proxies["default"] = ["httpProxy": proxyURL, "httpsProxy": proxyURL]
            json["proxies"] = proxies
        } else {
            json.removeValue(forKey: "proxies")
        }

        if let data = try? JSONSerialization.data(
            withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        {
            try? data.write(to: URL(fileURLWithPath: full))
        }
    }

    private func isDockerEnabled() -> Bool {
        let full = expand(dockerConfig)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: full)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let proxies = json["proxies"] as? [String: Any],
            let def = proxies["default"] as? [String: Any]
        else { return false }
        return def["httpProxy"] != nil
    }
}
