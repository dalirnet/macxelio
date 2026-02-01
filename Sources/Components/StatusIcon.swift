import SwiftUI

struct StatusIcon: View {
    enum Status {
        case loading
        case success
        case error
        case warning
    }

    let status: Status

    var body: some View {
        Group {
            switch status {
            case .loading:
                SpinnerView()
            case .success:
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(.green)
            case .error:
                Image(systemName: "xmark.circle")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(.red)
            case .warning:
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(.yellow)
            }
        }
        .frame(width: 48, height: 48)
    }
}

struct SpinnerView: View {
    @State private var rotation: Double = 0
    @State private var trimEnd: CGFloat = 0.1

    var body: some View {
        Circle()
            .trim(from: 0, to: trimEnd)
            .stroke(Color.secondary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 32, height: 32)
            .rotationEffect(Angle(degrees: rotation))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    trimEnd = 0.8
                }
            }
    }
}
