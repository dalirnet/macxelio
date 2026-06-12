import SwiftUI

struct StatusAvatar: View {
    let status: ConnectivityChecker.Status
    var checkInterval: Double = 0
    var checkSequence: Int = 0

    @Environment(\.controlActiveState) private var controlActiveState
    @State private var countdown: CGFloat = 0
    @State private var resolved: ConnectivityChecker.Status = .unknown
    @State private var fillWork: DispatchWorkItem?

    private var windowFocused: Bool { controlActiveState != .inactive }

    private var isChecking: Bool {
        if case .checking = status { return true }
        return false
    }

    private var display: ConnectivityChecker.Status {
        isChecking ? resolved : status
    }

    private var showsCountdown: Bool {
        switch display {
        case .ok, .error: return true
        default: return false
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(display.color.opacity(0.125))
                .frame(width: 36, height: 36)
                .overlay {
                    if isChecking {
                        LoadingRing(color: display.color)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .trim(from: 0, to: showsCountdown ? countdown : 0)
                            .stroke(
                                display.color.opacity(0.5),
                                style: StrokeStyle(lineWidth: 1, lineCap: .round)
                            )
                            .padding(1)
                    }
                }

            content
        }
        .onAppear { if !isChecking { resolved = status } }
        .onChange(of: status) { newValue in
            if case .checking = newValue {} else { resolved = newValue }
        }
        .onChange(of: isChecking) { checking in
            if checking { stopCountdown() }
        }
        .onChange(of: checkSequence) { _ in restartCountdown() }
        .onChange(of: windowFocused) { focused in
            if focused { restartCountdown() } else { stopCountdown() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch display {
        case .ok:
            Text(display.latencyText ?? "")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(display.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 3)
        case .error:
            Image(systemName: "exclamationmark.icloud.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(display.color)
        default:
            Image(systemName: "icloud.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(display.color)
        }
    }

    private func stopCountdown() {
        fillWork?.cancel()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { countdown = 0 }
    }

    private func restartCountdown() {
        guard windowFocused, showsCountdown, checkInterval > 0 else { return }
        fillWork?.cancel()
        let drain = 0.4
        withAnimation(.easeInOut(duration: drain)) { countdown = 0 }
        let work = DispatchWorkItem {
            withAnimation(.linear(duration: max(checkInterval - drain, 0.1))) { countdown = 1 }
        }
        fillWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + drain, execute: work)
    }
}

private struct LoadingRing: View {
    let color: Color
    @State private var trim: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .trim(from: 0, to: trim)
            .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            .padding(1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    trim = 1
                }
            }
    }
}
