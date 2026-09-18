import SwiftUI

struct ShutterButton: View {
    var action: () -> Void
    @GestureState private var pressed = false

    var body: some View {
        ZStack {
            Circle().strokeBorder(Color.onDark.opacity(0.9), lineWidth: 2.5)
            Circle()
                .fill(Color.onDark)
                .frame(width: pressed ? 54 : 62, height: pressed ? 54 : 62)
                .opacity(pressed ? 0.82 : 1)
        }
        .frame(width: 74, height: 74)
        .animation(.easeOut(duration: 0.12), value: pressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($pressed) { _, state, _ in state = true }
                .onEnded { _ in action() }
        )
    }
}
