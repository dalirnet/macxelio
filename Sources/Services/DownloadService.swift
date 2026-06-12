import Foundation

class DownloadService: NSObject, URLSessionDownloadDelegate {
    private var progressHandler: ((Double) -> Void)?
    private var continuation: CheckedContinuation<URL, Error>?
    private var session: URLSession?
    private var task: URLSessionDownloadTask?

    func cancel() {
        task?.cancel()
    }

    func install(_ name: String, progress: @escaping (Double) -> Void) async -> Bool {
        let dir = Tools.dir

        let spec = Self.spec(for: name)
        guard let assetURL = await Self.latestAsset(repo: spec.repo, matching: spec.match) else {
            return false
        }

        guard let archive = try? await download(assetURL, progress: progress) else {
            return false
        }
        defer { try? FileManager.default.removeItem(at: archive) }

        guard Self.extract(archive, keep: spec.keep, isTarGz: spec.isTarGz, into: dir) else {
            return false
        }

        let binary = dir.appendingPathComponent(name)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o755], ofItemAtPath: binary.path)
        return FileManager.default.isExecutableFile(atPath: binary.path)
    }

    private func download(_ url: URL, progress: @escaping (Double) -> Void) async throws -> URL {
        progressHandler = progress
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.session = session
        return try await withCheckedThrowingContinuation { cont in
            continuation = cont
            let downloadTask = session.downloadTask(with: url)
            task = downloadTask
            downloadTask.resume()
        }
    }

    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.moveItem(at: location, to: tmp)
        continuation?.resume(returning: tmp)
        continuation = nil
    }

    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async { self.progressHandler?(fraction) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        if let error = error {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }

    private static func latestAsset(repo: String, matching: @escaping (String) -> Bool) async
        -> URL?
    {
        guard let api = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            return nil
        }
        var req = URLRequest(url: api)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        guard let (data, _) = try? await URLSession.shared.data(for: req),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let assets = json["assets"] as? [[String: Any]]
        else { return nil }

        for asset in assets {
            if let name = asset["name"] as? String, matching(name),
                let urlString = asset["browser_download_url"] as? String,
                let url = URL(string: urlString)
            {
                return url
            }
        }
        return nil
    }

    private static func extract(_ archive: URL, keep: [String], isTarGz: Bool, into dir: URL)
        -> Bool
    {
        let fm = FileManager.default
        let tmp = dir.appendingPathComponent("extract-tmp")
        try? fm.removeItem(at: tmp)
        try? fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tmp) }

        let extracted =
            isTarGz
            ? Shell.run("/usr/bin/tar", ["-xzf", archive.path, "-C", tmp.path])
            : Shell.run("/usr/bin/unzip", ["-o", archive.path, "-d", tmp.path])
        guard extracted else { return false }

        for name in keep {
            guard let found = findFile(name, in: tmp) else { return false }
            let dest = dir.appendingPathComponent(name)
            try? fm.removeItem(at: dest)
            do { try fm.moveItem(at: found, to: dest) } catch { return false }
        }
        return true
    }

    private static func findFile(_ name: String, in dir: URL) -> URL? {
        guard
            let enumerator = FileManager.default.enumerator(
                at: dir, includingPropertiesForKeys: nil)
        else { return nil }
        for case let url as URL in enumerator where url.lastPathComponent == name { return url }
        return nil
    }

    private struct Spec {
        let repo: String
        let keep: [String]
        let isTarGz: Bool
        let match: (String) -> Bool
    }

    private static func spec(for _: String) -> Spec {
        let suffix = arch == "arm64" ? "arm64-v8a" : "64"
        return Spec(
            repo: "XTLS/Xray-core",
            keep: ["xray", "geoip.dat", "geosite.dat"],
            isTarGz: false,
            match: { $0 == "Xray-macos-\(suffix).zip" })
    }

    private static var arch: String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(cString: raw.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
    }
}
