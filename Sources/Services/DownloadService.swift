import Foundation

class DownloadService: NSObject, URLSessionDownloadDelegate {
    private var progressHandler: ((Double, Int64) -> Void)?
    private var completionHandler: ((Result<URL, Error>) -> Void)?
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var resumeData: Data?

    private let resumeDataPath: URL = {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/macxelio")
        return configDir.appendingPathComponent("download.resume")
    }()

    func download(
        from url: URL,
        progress: @escaping (Double, Int64) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        self.progressHandler = progress
        self.completionHandler = completion

        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 6
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 600
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.connectionProxyDictionary = [:]

        session = URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: nil
        )

        // Try to resume from saved data
        if let savedResumeData = try? Data(contentsOf: resumeDataPath) {
            let task = session!.downloadTask(withResumeData: savedResumeData)
            task.priority = URLSessionTask.highPriority
            self.downloadTask = task
            task.resume()
            try? FileManager.default.removeItem(at: resumeDataPath)
        } else {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData

            let task = session!.downloadTask(with: request)
            task.priority = URLSessionTask.highPriority
            self.downloadTask = task
            task.resume()
        }
    }

    func cancel() {
        downloadTask?.cancel(byProducingResumeData: { [weak self] data in
            if let data = data, let path = self?.resumeDataPath {
                try? data.write(to: path)
            }
        })
        downloadTask = nil
        session?.invalidateAndCancel()
        session = nil
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Clear any saved resume data on successful completion
        try? FileManager.default.removeItem(at: resumeDataPath)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString + ".zip"
        )
        do {
            try FileManager.default.copyItem(at: location, to: tempURL)
            completionHandler?(.success(tempURL))
        } catch {
            completionHandler?(.failure(error))
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            progressHandler?(progress, totalBytesWritten)
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error as NSError? {
            // Save resume data if available
            if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                try? resumeData.write(to: resumeDataPath)
            }
            completionHandler?(.failure(error))
        }
    }

    // MARK: - Extraction

    static func extractZip(_ zipPath: URL, to destination: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = ["-o", zipPath.path, "-d", destination.path]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
                continuation.resume(returning: process.terminationStatus == 0)
            } catch {
                continuation.resume(returning: false)
            }
        }
    }

    // MARK: - Architecture Helper

    static func getArchitecture() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return machine == "arm64" ? "arm64-v8a" : "64"
    }

    // MARK: - Resume Data Management

    static func hasResumeData() -> Bool {
        let resumeDataPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/macxelio/download.resume")
        return FileManager.default.fileExists(atPath: resumeDataPath.path)
    }

    static func clearResumeData() {
        let resumeDataPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/macxelio/download.resume")
        try? FileManager.default.removeItem(at: resumeDataPath)
    }
}
