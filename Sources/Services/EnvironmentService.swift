import Foundation

struct ProxyEnvironment: Identifiable {
    enum Category: String, CaseIterable {
        case packageManager = "Package Managers"
        case versionControl = "Version Control"
        case downloader = "Downloaders"
        case container = "Containers"
        case shell = "Shell Environment"
    }

    let id: String
    let name: String
    let category: Category
    let commands: [String]
    let configPath: String
    let body: ((String) -> String)?
}

@MainActor
class EnvironmentService: ObservableObject {
    @Published var available: Set<String> = []
    @Published var enabled: Set<String> = []

    private let markerStart = "# >>> macxelio proxy >>>"
    private let markerEnd = "# <<< macxelio proxy <<<"
    private let dockerId = "docker"

    let environments: [ProxyEnvironment] = [
        ProxyEnvironment(
            id: "npm", name: "npm / pnpm / yarn",
            category: .packageManager, commands: ["npm", "pnpm", "yarn"],
            configPath: "~/.npmrc",
            body: { url in "proxy=\(url)\nhttps-proxy=\(url)" }
        ),
        ProxyEnvironment(
            id: "pip", name: "pip",
            category: .packageManager, commands: ["pip", "pip3"],
            configPath: "~/.config/pip/pip.conf",
            body: { url in "[global]\nproxy = \(url)" }
        ),
        ProxyEnvironment(
            id: "conda", name: "conda",
            category: .packageManager, commands: ["conda"],
            configPath: "~/.condarc",
            body: { url in "proxy_servers:\n  http: \(url)\n  https: \(url)" }
        ),
        ProxyEnvironment(
            id: "cargo", name: "cargo",
            category: .packageManager, commands: ["cargo"],
            configPath: "~/.cargo/config.toml",
            body: { url in "[http]\nproxy = \"\(url)\"" }
        ),
        ProxyEnvironment(
            id: "gem", name: "gem",
            category: .packageManager, commands: ["gem"],
            configPath: "~/.gemrc",
            body: { url in "http_proxy: \(url)" }
        ),
        ProxyEnvironment(
            id: "git", name: "git",
            category: .versionControl, commands: ["git"],
            configPath: "~/.gitconfig",
            body: { url in "[http]\n\tproxy = \(url)" }
        ),
        ProxyEnvironment(
            id: "curl", name: "curl",
            category: .downloader, commands: ["curl"],
            configPath: "~/.curlrc",
            body: { url in "proxy = \"\(url)\"" }
        ),
        ProxyEnvironment(
            id: "wget", name: "wget",
            category: .downloader, commands: ["wget"],
            configPath: "~/.wgetrc",
            body: { url in "http_proxy = \(url)\nhttps_proxy = \(url)\nuse_proxy = on" }
        ),
        ProxyEnvironment(
            id: "docker", name: "docker",
            category: .container, commands: ["docker"],
            configPath: "", body: nil
        ),
        ProxyEnvironment(
            id: "shell", name: "Shell env",
            category: .shell, commands: [],
            configPath: "~/.zshrc",
            body: { url in
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
    ]

    private var proxyURL: String {
        "http://127.0.0.1:\(AppConfig.shared.httpPort)"
    }

    func refresh() {
        var on: Set<String> = []
        for environment in environments {
            if environment.id == dockerId {
                if isDockerEnabled() { on.insert(environment.id) }
            } else if fileHasBlock(environment.configPath) {
                on.insert(environment.id)
            }
        }
        enabled = on

        detectAvailable()
    }

    func setEnabled(_ environment: ProxyEnvironment, _ on: Bool) {
        if environment.id == dockerId {
            setDockerProxy(on)
        } else if on {
            writeBlock(environment.configPath, body: environment.body?(proxyURL) ?? "")
        } else {
            removeBlock(environment.configPath)
        }

        if on { enabled.insert(environment.id) } else { enabled.remove(environment.id) }
    }

    func isAvailable(_ environment: ProxyEnvironment) -> Bool {
        environment.commands.isEmpty || !available.isDisjoint(with: environment.commands)
    }

    private func detectAvailable() {
        let names = Set(environments.flatMap { $0.commands })
        Task.detached { [names] in
            let list = names.joined(separator: " ")
            let out = Shell.output(
                "/bin/zsh",
                ["-lc", "for c in \(list); do command -v $c >/dev/null 2>&1 && echo $c; done"])
            let found = Set(out.split(separator: "\n").map(String.init))
            await MainActor.run { self.available = found }
        }
    }

    private func expand(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }

    private func fileHasBlock(_ path: String) -> Bool {
        guard let content = try? String(contentsOfFile: expand(path), encoding: .utf8)
        else { return false }
        return content.contains(markerStart)
    }

    private func writeBlock(_ path: String, body: String) {
        let full = expand(path)
        let dir = (full as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true)

        var content = (try? String(contentsOfFile: full, encoding: .utf8)) ?? ""
        content = strippedBlock(content)
        if !content.isEmpty && !content.hasSuffix("\n") { content += "\n" }
        content += "\(markerStart)\n\(body)\n\(markerEnd)\n"
        try? content.write(toFile: full, atomically: true, encoding: .utf8)
    }

    private func removeBlock(_ path: String) {
        let full = expand(path)
        guard let content = try? String(contentsOfFile: full, encoding: .utf8) else { return }
        try? strippedBlock(content).write(toFile: full, atomically: true, encoding: .utf8)
    }

    private func strippedBlock(_ content: String) -> String {
        let lines = content.components(separatedBy: "\n")
        var result: [String] = []
        var inside = false
        for line in lines {
            if line == markerStart {
                inside = true
                continue
            }
            if line == markerEnd {
                inside = false
                continue
            }
            if !inside { result.append(line) }
        }
        return result.joined(separator: "\n")
    }

    private func setDockerProxy(_ on: Bool) {
        let full = expand("~/.docker/config.json")
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
        let full = expand("~/.docker/config.json")
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: full)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let proxies = json["proxies"] as? [String: Any],
            let def = proxies["default"] as? [String: Any]
        else { return false }
        return def["httpProxy"] != nil
    }
}
