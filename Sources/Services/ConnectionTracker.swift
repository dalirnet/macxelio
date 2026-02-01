import Foundation

class ConnectionTracker: ObservableObject {
    @Published var connections: [Connection] = []
    @Published var uploadSpeed: Double = 0
    @Published var downloadSpeed: Double = 0

    private var timer: Timer?

    struct Connection: Identifiable {
        var id: UUID = UUID()
        var host: String
        var port: Int
        var action: String
        var isActive: Bool
        var createdAt: Date
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func clear() {
        connections.removeAll()
        uploadSpeed = 0
        downloadSpeed = 0
    }

    private func updateStats() {
        // Note: Full implementation requires xray stats API integration
        // Real implementation would query: grpc://127.0.0.1:10085/xray.app.stats.command.StatsService/QueryStats
    }

    var totalConnections: Int {
        connections.count
    }

    var formattedUploadSpeed: String {
        formatSpeed(uploadSpeed)
    }

    var formattedDownloadSpeed: String {
        formatSpeed(downloadSpeed)
    }

    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1_000_000 {
            return String(format: "%.1f MB/s", bytesPerSecond / 1_000_000)
        } else if bytesPerSecond >= 1_000 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1_000)
        } else {
            return String(format: "%.0f B/s", bytesPerSecond)
        }
    }
}
