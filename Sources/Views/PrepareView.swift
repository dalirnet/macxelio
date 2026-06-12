import SwiftUI

struct PrepareView: View {
    var onComplete: () -> Void

    @State private var state: SetupState = .checking
    @State private var progress: Double = 0
    @State private var downloadService: DownloadService?
    @State private var isCancelling = false
    @State private var pulse: CGFloat = 1.0

    enum SetupState {
        case checking
        case needsInstall([String])
        case downloading
        case done
        case failed(String)
    }

    var body: some View {
        ViewLayout(
            headerLeft: {
                HeaderTitle(title: "Prepare", showFlame: true)
            },
            headerRight: { EmptyView() },
            content: {
                VStack(spacing: 0) {
                    Spacer().frame(maxHeight: 110)

                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.08))
                                .frame(width: 96, height: 96)
                                .scaleEffect(pulse)
                            Circle()
                                .fill(Color.accentColor.opacity(0.05))
                                .frame(width: 72, height: 72)
                                .scaleEffect(pulse * 0.97)
                            iconView
                        }

                        VStack(spacing: 4) {
                            Text(statusTitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)

                            if let subtitle = statusSubtitle {
                                Text(subtitle)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)

                        actionButton
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.3), value: stateKey)
            }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = 1.08
            }
            Task { await check() }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch state {
        case .checking:
            ProgressView()
                .controlSize(.small)
        case .needsInstall:
            Image(systemName: "shippingbox")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.accentColor)
        case .downloading:
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.2), value: progress)
                DownloadArrow()
            }
            .frame(width: 46, height: 46)
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.accentColor)
        case .failed:
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.accentColor)
        }
    }

    private var statusTitle: String {
        switch state {
        case .checking: return "Preparing"
        case .needsInstall: return "Set up Macxelio"
        case .downloading: return "Setting up"
        case .done: return "Ready"
        case .failed: return "Setup failed"
        }
    }

    private var statusSubtitle: String? {
        switch state {
        case .needsInstall: return "A quick one-time setup"
        case .failed(let message): return message
        case .checking, .downloading, .done: return nil
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch state {
        case .checking:
            EmptyView()
        case .needsInstall(let tools):
            Button("Set up") { Task { await install(tools) } }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        case .downloading:
            Button("Cancel") { cancel() }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        case .done:
            Button("Continue") { onComplete() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        case .failed:
            Button("Retry") { Task { await check() } }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
    }

    private var stateKey: String {
        switch state {
        case .checking: return "checking"
        case .needsInstall: return "needsInstall"
        case .downloading: return "downloading"
        case .done: return "done"
        case .failed: return "failed"
        }
    }

    private func check() async {
        state = .checking
        let missing = await Task.detached { Tools.missing() }.value
        state = missing.isEmpty ? .done : .needsInstall(missing)
    }

    private func install(_ tools: [String]) async {
        progress = 0
        state = .downloading
        let total = Double(tools.count)

        for (index, tool) in tools.enumerated() {
            let service = DownloadService()
            downloadService = service
            let ok = await service.install(tool) { self.progress = (Double(index) + $0) / total }
            downloadService = nil

            if isCancelling {
                isCancelling = false
                await check()
                return
            }
            if !ok {
                state = .failed("Check your connection and try again")
                return
            }
        }
        progress = 1
        state = .done
    }

    private func cancel() {
        isCancelling = true
        downloadService?.cancel()
    }
}

private struct DownloadArrow: View {
    @State private var animate = false

    var body: some View {
        Image(systemName: "arrow.down")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.accentColor)
            .offset(y: animate ? 5 : -1)
            .opacity(animate ? 0 : 0.8)
            .onAppear {
                withAnimation(.easeIn(duration: 1).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}
