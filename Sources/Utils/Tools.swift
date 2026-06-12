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

    static func path(_ name: String) -> String? {
        let path = url(name).path
        return FileManager.default.isExecutableFile(atPath: path) ? path : nil
    }

    static func isInstalled(_ name: String) -> Bool { path(name) != nil }

    static func missing() -> [String] {
        [xray].filter { !isInstalled($0) }
    }

    static func xrayAssetDir() -> String? { dir.path }
}
