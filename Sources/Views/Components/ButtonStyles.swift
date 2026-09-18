import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelAction)
            .tracking(-0.4)
            .foregroundStyle(Color.onDark)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(configuration.isPressed ? Color.brandPressed : Color.brandFill, in: Capsule())
    }
}

// a capsule sized for the viewfinder, which is dark in both modes
struct ViewfinderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelAction)
            .foregroundStyle(Color.onDark)
            .padding(.horizontal, 20)
            .frame(height: 40)
            .background(configuration.isPressed ? Color.brandPressed : Color.brandFill, in: Capsule())
    }
}
