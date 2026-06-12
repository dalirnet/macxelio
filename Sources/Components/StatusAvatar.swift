import SwiftUI

struct StatusAvatar: View {
    let status: ConnectivityChecker.Status
    var checkInterval: Double = 0
    var checkSequence: Int = 0

    @Environment(\.controlActiveState) private var controlActiveState
    @State private var countdown: CGFloat = 0

    private var windowFocused: Bool { controlActiveState != .inactive }

    private var showsCountdown: Bool {
        switch status {
        case .ok, .error: return true
        default: return false
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(status.color.opacity(0.125))
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .trim(from: 0, to: showsCountdown ? countdown : 0)
                        .stroke(
                            status.color.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1, lineCap: .round)
                        )
                        .padding(1)
                )

            content
        }
        .onChange(of: checkSequence) { _ in restartCountdown() }
        .onChange(of: windowFocused) { focused in
            if focused {
                restartCountdown()
            } else {
                var reset = Transaction()
                reset.disablesAnimations = true
                withTransaction(reset) { countdown = 0 }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch status {
        case .checking:
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.8)
        case .ok:
            Text(status.latencyText ?? "")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(status.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 3)
        case .error:
            Image(systemName: "exclamationmark.icloud.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(status.color)
        case .unknown:
            Image(systemName: "icloud.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(status.color)
        }
    }

    /// Drains the ring smoothly, then refills it over the interval until the next
    /// check. Runs only while the window is focused to avoid background animation.
    private func restartCountdown() {
        guard windowFocused, showsCountdown, checkInterval > 0 else { return }
        let drain = 0.4
        withAnimation(.easeInOut(duration: drain)) { countdown = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + drain) {
            guard windowFocused else { return }
            withAnimation(.linear(duration: max(checkInterval - drain, 0.1))) { countdown = 1 }
        }
    }
}
