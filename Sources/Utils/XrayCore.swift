import Foundation

class XrayCore: ObservableObject {
    @Published var isRunning = false
    @Published var currentServer: Server?
    
    private var process: Process?
    
    func start(with server: Server) async throws {
        // TODO: Implement Xray core integration
        isRunning = true
        currentServer = server
    }
    
    func stop() {
        process?.terminate()
        isRunning = false
        currentServer = nil
    }
    
    func restart() async throws {
        guard let server = currentServer else { return }
        stop()
        try await start(with: server)
    }
}
