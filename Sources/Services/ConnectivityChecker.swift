import SwiftUI

@MainActor
class ConnectivityChecker: ObservableObject {
    static let shared = ConnectivityChecker()

    enum Status: Equatable {
        case unknown
        case checking
        case ok(latency: Int)
        case error

        var color: Color {
            switch self {
            case .unknown, .checking:
                return .secondary
            case .ok(let latency):
                return latency <= 500 ? .green : .yellow
            case .error:
                return .red
            }
        }

        var latencyText: String? {
            guard case .ok(let ms) = self else { return nil }
            let seconds = Double(ms) / 1000
            var text =
                seconds >= 1
                ? String(format: "%.1f", seconds)
                : String(format: "%.2f", seconds)
            if text.contains(".") {
                while text.hasSuffix("0") { text.removeLast() }
                if text.hasSuffix(".") { text.removeLast() }
            }
            if text.hasPrefix("0.") { text.removeFirst() }
            return text + "s"
        }
    }

    @Published var status: Status = .unknown
    /// Seconds until the next check, and a counter that ticks once per completed
    /// check so views can drive a fresh countdown animation each cycle.
    @Published private(set) var nextInterval: Double = 0
    @Published private(set) var checkSequence: Int = 0

    private let timeout: TimeInterval = 5
    private let baseInterval = 5.0
    private let stepInterval = 2.5
    private let maxInterval = 60.0

    private var task: Task<Void, Never>?
    private var consecutiveOK = 0

    func start() {
        restart()
    }

    func check() {
        consecutiveOK = 0
        restart()
    }

    private func restart() {
        task?.cancel()
        task = Task { [weak self] in await self?.loop() }
    }

    private func loop() async {
        if AppConfig.shared.selectedProxyId != nil { status = .checking }

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        while !Task.isCancelled {
            await performCheck()

            let seconds = min(baseInterval + Double(consecutiveOK) * stepInterval, maxInterval)
            nextInterval = seconds
            checkSequence += 1
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    }

    private func performCheck() async {
        let config = AppConfig.shared

        guard config.selectedProxyId != nil,
            let server = TestServer(rawValue: config.testServer),
            let url = URL(string: server.url)
        else {
            status = .unknown
            consecutiveOK = 0
            return
        }

        if let latency = await Self.measure(
            url: url, inboundPort: AppConfig.testPort, timeout: timeout)
        {
            status = .ok(latency: latency)
            consecutiveOK += 1
        } else {
            status = .error
            consecutiveOK = 0
        }
    }

    nonisolated private static func measure(
        url: URL, inboundPort: Int, timeout: TimeInterval
    ) async -> Int? {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPEnable as String: true,
            kCFNetworkProxiesHTTPProxy as String: "127.0.0.1",
            kCFNetworkProxiesHTTPPort as String: inboundPort,
            kCFNetworkProxiesHTTPSEnable as String: true,
            kCFNetworkProxiesHTTPSProxy as String: "127.0.0.1",
            kCFNetworkProxiesHTTPSPort as String: inboundPort,
        ]

        let session = URLSession(configuration: config)
        let start = Date()
        do {
            let (_, response) = try await session.data(from: url)
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard (200...399).contains(code) else { return nil }
            return Int(Date().timeIntervalSince(start) * 1000)
        } catch {
            return nil
        }
    }
}
