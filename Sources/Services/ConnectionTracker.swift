import Foundation

@MainActor
class ConnectionTracker: ObservableObject {
    @Published var totalUpload: Int64 = 0
    @Published var totalDownload: Int64 = 0
    @Published var connections: [Connection] = []

    private var timer: Timer?
    private let interval: TimeInterval = 2.0

    private let binaryPath = Tools.url(Tools.xray)
    private let accessLogPath = Tools.url("access.log").path

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let path = binaryPath
        let logPath = accessLogPath
        Task.detached {
            let stats = Self.queryStats(binaryPath: path)
            let up = stats["outbound>>>proxy>>>traffic>>>uplink"] ?? 0
            let down = stats["outbound>>>proxy>>>traffic>>>downlink"] ?? 0
            let conns = Self.parseConnections(logPath: logPath)
            await MainActor.run {
                self.update(up: up, down: down)
                self.connections = conns
            }
        }
    }

    nonisolated private static let acceptRegex = try! NSRegularExpression(
        pattern: #"accepted\s+(?:\w+:)?/*([^\s\[]+)\s+\[([^\]]+)\]"#)

    nonisolated private static func parseConnections(logPath: String) -> [Connection] {
        guard let handle = FileHandle(forReadingAtPath: logPath) else { return [] }
        defer { try? handle.close() }

        let size = (try? handle.seekToEnd()) ?? 0
        let window: UInt64 = 32768
        try? handle.seek(toOffset: size > window ? size - window : 0)
        guard let data = try? handle.readToEnd(),
            let text = String(data: data, encoding: .utf8)
        else { return [] }

        var result: [Connection] = []
        var seen = Set<String>()
        for line in text.split(separator: "\n").reversed() {
            guard let conn = parseLine(String(line)), !seen.contains(conn.host) else { continue }
            seen.insert(conn.host)
            result.append(conn)
            if result.count >= 20 { break }
        }
        return result
    }

    nonisolated private static func parseLine(_ line: String) -> Connection? {
        let range = NSRange(line.startIndex..., in: line)
        guard let match = acceptRegex.firstMatch(in: line, range: range),
            let hostRange = Range(match.range(at: 1), in: line),
            let tagsRange = Range(match.range(at: 2), in: line)
        else { return nil }

        let host = String(line[hostRange])
        let tags = String(line[tagsRange])
        let separator = tags.contains(">>") ? ">>" : "->"
        let parts = tags.components(separatedBy: separator)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return nil }

        let inbound = parts[0].replacingOccurrences(of: "-inbound", with: "")
        let outbound = parts[1]
        if inbound == "api" || outbound == "api" || inbound == "test" { return nil }
        return Connection(host: host, inbound: inbound, route: outbound)
    }

    private func update(up: Int64, down: Int64) {
        totalUpload = up
        totalDownload = down
    }

    nonisolated private static func queryStats(binaryPath: URL) -> [String: Int64] {
        guard FileManager.default.fileExists(atPath: binaryPath.path) else { return [:] }

        let output = Shell.output(
            binaryPath.path, ["api", "statsquery", "--server=127.0.0.1:\(AppConfig.apiPort)"])

        guard let data = output.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let stats = json["stat"] as? [[String: Any]]
        else { return [:] }

        var result: [String: Int64] = [:]
        for entry in stats {
            guard let name = entry["name"] as? String else { continue }
            if let str = entry["value"] as? String, let value = Int64(str) {
                result[name] = value
            } else if let value = entry["value"] as? Int64 {
                result[name] = value
            }
        }
        return result
    }
}
