import SwiftUI

/// Small spinner for footer/inline use
struct Spinner: View {
    @State private var rotation: Double = 0
    @State private var trimEnd: CGFloat = 0.1

    var body: some View {
        Circle()
            .trim(from: 0, to: trimEnd)
            .stroke(Color.secondary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .frame(width: 14, height: 14)
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
