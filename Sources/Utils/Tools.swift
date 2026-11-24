import Foundation

enum Tools {
    static let xray = "xray"

    static let dir: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/macxelio")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func url(_ name: String) -> URL { dir.appendingPathComponent(name) }

    static let config = url("config.json")
    static let accessLog = url("access.log")
    static let errorLog = url("xray.log")
    static let bootLog = url("boot.log")

    static func path(_ name: String) -> String? {
        let path = url(name).path
        return FileManager.default.isExecutableFile(atPath: path) ? path : nil
    }

    static func isInstalled(_ name: String) -> Bool { path(name) != nil }

    static func missing() -> [String] {
        [xray].filter { !isInstalled($0) }
    }

    static func xrayAssetDir() -> String? { dir.path }

    private static var versionCache: (stamp: String, version: String?)?

    static func xrayVersion() -> String? {
        guard let path = path(xray),
            let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        else { return nil }
        let stamp = "\(attrs[.size] ?? 0)-\(attrs[.modificationDate] ?? "")"
        if let cache = versionCache, cache.stamp == stamp { return cache.version }
        let parts = Shell.output(path, ["version"])
            .components(separatedBy: "\n").first?.components(separatedBy: " ")
        let version = (parts?.count ?? 0) >= 2 ? parts?[1] : nil
        versionCache = (stamp, version)
        return version
    }
}
