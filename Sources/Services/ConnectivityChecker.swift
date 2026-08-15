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
    @Published private(set) var nextInterval: Double = 0
    @Published private(set) var checkSequence: Int = 0
    @Published private(set) var probes: [UUID: Status] = [:]

    private let timeout: TimeInterval = 3
    private let debounceDelay = 0.3
    private let baseInterval = 5.0
    private let stepInterval = 2.5
    private let maxInterval = 60.0

    private var task: Task<Void, Never>?
    private var consecutiveOK = 0
    private var session: URLSession?
    private var probeTasks: [UUID: Task<Void, Never>] = [:]

    func start() {
        restart()
    }

    func check() {
        consecutiveOK = 0
        session?.invalidateAndCancel()
        session = nil
        restart()
    }

    func probe(_ proxy: Proxy) {
        let config = AppConfig.shared

        guard let port = config.probePort(for: proxy),
            let server = TestServer(rawValue: config.testServer),
            let url = URL(string: server.url)
        else {
            probes[proxy.id] = .unknown
            return
        }

        probeTasks[proxy.id]?.cancel()
        probes[proxy.id] = .checking

        probeTasks[proxy.id] = Task { [weak self] in
            guard let self else { return }
            let session = Self.makeSession(inboundPort: port, timeout: self.timeout)
            let latency = await Self.measure(url: url, session: session)
            session.invalidateAndCancel()

            guard !Task.isCancelled else { return }
            self.probes[proxy.id] = latency.map { .ok(latency: $0) } ?? .error
            self.probeTasks[proxy.id] = nil
        }
    }

    func forgetProbe(_ id: UUID) {
        probeTasks[id]?.cancel()
        probeTasks[id] = nil
        probes[id] = nil
    }

    private var currentInterval: Double {
        min(baseInterval + Double(consecutiveOK) * stepInterval, maxInterval)
    }

    private func restart() {
        status = AppConfig.shared.selectedProxyId != nil ? .checking : .unknown
        task?.cancel()
        task = Task { [weak self] in await self?.loop() }
    }

    private func loop() async {
        try? await pause(debounceDelay)

        while !Task.isCancelled {
            await performCheck()

            nextInterval = currentInterval
            checkSequence += 1
            try? await pause(currentInterval)
        }
    }

    private func pause(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
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

        let session = session ?? Self.makeSession(inboundPort: AppConfig.testPort, timeout: timeout)
        self.session = session

        if let latency = await Self.measure(url: url, session: session) {
            status = .ok(latency: latency)
            consecutiveOK += 1
        } else {
            status = .error
            consecutiveOK = 0
        }
    }

    nonisolated private static func makeSession(inboundPort: Int, timeout: TimeInterval)
        -> URLSession
    {
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
        return URLSession(configuration: config)
    }

    nonisolated private static func measure(url: URL, session: URLSession) async -> Int? {
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
