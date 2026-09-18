import SwiftUI

// flash and zoom are the same chip with a different payload
struct CameraChip<Content: View>: View {
    var filled = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            // a 32x32 capsule is a circle. only a label too wide for it pushes
            // the shape out into a pill.
            .padding(.horizontal, 6)
            .frame(minWidth: 32, minHeight: 32)
            .background(filled ? Color.onDark : Color.viewfinder.opacity(0.45), in: Capsule())
            .frame(minWidth: 44, minHeight: 44)
    }
}
