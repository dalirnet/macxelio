import Foundation

struct ProxyEnvironment: Identifiable {
    enum Category: String, CaseIterable {
        case general = "General"
        case editor = "Editors"
        case packageManager = "Package Managers"
    }

    enum Kind {
        case line(path: String, body: (String) -> String)
        case json(path: String, key: String)
        case docker
        case command(set: (String) -> String, unset: String, check: String)
    }

    let id: String
    let name: String
    let category: Category
    let commands: [String]
    let kind: Kind
    var appName: String? = nil
}

@MainActor
class EnvironmentService: ObservableObject {
    @Published var available: Set<String> = []
    @Published var enabled: Set<String> = []
    @Published var checking: Set<String> = []

    private let dockerConfig = "~/.docker/config.json"

    let environments: [ProxyEnvironment] = [
        ProxyEnvironment(
            id: "shell", name: "Shell env",
            category: .general, commands: [],
            kind: .line(path: "~/.zshrc") { url in
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
            id: "git", name: "git",
            category: .general, commands: ["git"],
            kind: .command(set: Commands.gitSet, unset: Commands.gitUnset, check: Commands.gitCheck)
        ),
        ProxyEnvironment(
            id: "docker", name: "docker",
            category: .general, commands: ["docker"],
            kind: .docker
        ),
        ProxyEnvironment(
            id: "zed", name: "Zed",
            category: .editor, commands: ["zed"],
            kind: .json(path: "~/.config/zed/settings.json", key: "proxy"), appName: "Zed"
        ),
        ProxyEnvironment(
            id: "vscode", name: "VS Code",
            category: .editor, commands: ["code"],
            kind: .json(
                path: "~/Library/Application Support/Code/User/settings.json", key: "http.proxy"),
            appName: "Visual Studio Code"
        ),
        ProxyEnvironment(
            id: "npm", name: "npm",
            category: .packageManager, commands: ["npm", "pnpm", "yarn"],
            kind: .command(set: Commands.npmSet, unset: Commands.npmUnset, check: Commands.npmCheck)
        ),
        ProxyEnvironment(
            id: "pip", name: "pip",
            category: .packageManager, commands: ["pip", "pip3"],
            kind: .command(set: Commands.pipSet, unset: Commands.pipUnset, check: Commands.pipCheck)
        ),
        ProxyEnvironment(
            id: "go", name: "go",
            category: .packageManager, commands: ["go"],
            kind: .line(path: "~/.config/go/env") { url in "http_proxy=\(url)\nhttps_proxy=\(url)" }
        ),
    ]

    private var proxyURL: String {
        "http://127.0.0.1:\(AppConfig.shared.httpPort)"
    }

    func refresh() {
        var on: Set<String> = []
        var commandChecks: [(id: String, check: String)] = []
        for environment in environments {
            switch environment.kind {
            case .docker:
                if isDockerEnabled() { on.insert(environment.id) }
            case .command(_, _, let check):
                commandChecks.append((environment.id, check))
            case .json(let path, let key):
                if hasJSONLine(path, key: key) { on.insert(environment.id) }
            case .line(let path, let body):
                if hasConfig(path, body: body(proxyURL)) { on.insert(environment.id) }
            }
        }
        let commandIDs = Set(commandChecks.map(\.id))
        enabled = on
        checking = commandIDs

        detectAvailable()

        Task.detached { [commandChecks, commandIDs] in
            var found: Set<String> = []
            for item in commandChecks
            where Shell.output("/bin/zsh", ["-lc", item.check]).contains("127.0.0.1") {
                found.insert(item.id)
            }
            let detected = found
            await MainActor.run {
                self.enabled.formUnion(detected)
                self.checking.subtract(commandIDs)
            }
        }
    }

    func setEnabled(_ environment: ProxyEnvironment, _ on: Bool) {
        switch environment.kind {
        case .docker:
            setDockerProxy(on)
        case .command(let set, let unset, _):
            let command = on ? set(proxyURL) : unset
            Task.detached { Shell.run("/bin/zsh", ["-lc", command]) }
        case .json(let path, let key):
            setJSONLine(path, key: key, on: on)
        case .line(let path, let body):
            setConfig(path, body: body(proxyURL), on: on)
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

private enum Commands {
    static func gitSet(_ url: String) -> String {
        "git config --global --replace-all http.proxy \(url); "
            + "git config --global --replace-all https.proxy \(url)"
    }
    static let gitUnset =
        "git config --global --unset-all http.proxy; "
        + "git config --global --unset-all https.proxy"
    static let gitCheck = "git config --global --get-all http.proxy"

    static let nodeKeys = "proxy http-proxy https-proxy httpProxy httpsProxy"
    static func npmSet(_ url: String) -> String {
        "for t in npm pnpm yarn; do command -v $t >/dev/null 2>&1 && "
            + "for k in \(nodeKeys); do $t config set $k \(url) 2>/dev/null; done; done"
    }
    static let npmUnset =
        "for t in npm pnpm yarn; do command -v $t >/dev/null 2>&1 && "
        + "for k in \(nodeKeys); do $t config delete $k 2>/dev/null; "
        + "$t config unset $k 2>/dev/null; done; done"
    static let npmCheck =
        "for t in npm pnpm yarn; do $t config get proxy 2>/dev/null; "
        + "$t config get httpProxy 2>/dev/null; done"

    static func pipSet(_ url: String) -> String { pip("config set global.proxy \(url)") }
    static let pipUnset = pip("config unset global.proxy")
    static let pipCheck = pip("config get global.proxy")
    private static func pip(_ args: String) -> String { "pip3 \(args) 2>/dev/null || pip \(args)" }
}
