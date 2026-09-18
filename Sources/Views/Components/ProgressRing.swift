import SwiftUI

// the shutter becomes a ring while the model runs
struct ProgressRing: View {
    @State private var spinning = false

    var body: some View {
        ZStack {
            Circle().stroke(Color.onDark.opacity(0.22), lineWidth: 5)
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.brandText, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(spinning ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spinning)
        }
        .onAppear { spinning = true }
    }
}
