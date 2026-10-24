import SwiftUI

struct ShutterButton: View {
    var action: () -> Void
    @GestureState private var pressed = false

    var body: some View {
        ZStack {
            Circle().strokeBorder(.white, lineWidth: 3)
            Circle()
                .fill(.white)
                .frame(width: pressed ? 54 : 62, height: pressed ? 54 : 62)
                .opacity(pressed ? 0.75 : 1)
        }
        .frame(width: 74, height: 74)
        .animation(.easeOut(duration: 0.12), value: pressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($pressed) { _, state, _ in state = true }
                .onEnded { _ in action() }
        )
        .accessibilityLabel("Take a photo")
        .accessibilityAddTraits(.isButton)
    }
}

// the 0.5x / 1x / 2x group on the camera. only the stops the lens really has.
struct ZoomPicker: View {
    var stops: [CGFloat]
    var current: CGFloat
    var pick: (CGFloat) -> Void

    var body: some View {
        HStack(spacing: Space.dot) {
            ForEach(stops, id: \.self) { stop in
                let on = abs(stop - current) < 0.05
                Button { pick(stop) } label: {
                    Text(label(stop))
                        .font(MoopType.micro)
                        .foregroundStyle(on ? Moop.onAccent : .white)
                        .frame(minWidth: 38, minHeight: 32)
                        .background(on ? Moop.citrus : Moop.pill,
                                    in: RoundedRectangle(cornerRadius: Edge.slight, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Space.dot)
        .background(Moop.pill.opacity(0.75), in: RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
    }

    private func label(_ v: CGFloat) -> String {
        let r = (v * 10).rounded() / 10
        return r == r.rounded() ? "\(Int(r))×" : String(format: "%.1f×", r)
    }
}
