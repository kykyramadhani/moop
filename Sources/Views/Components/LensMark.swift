import SwiftUI

// the moop mark: ring, iris, highlight
struct LensMark: View {
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            ZStack(alignment: .topLeading) {
                Circle()
                    .strokeBorder(tint, lineWidth: d * 0.082)
                    .frame(width: d, height: d)
                Circle()
                    .fill(tint)
                    .frame(width: d * 0.355, height: d * 0.355)
                    .offset(x: d * 0.3225, y: d * 0.3225)
                Circle()
                    .fill(tint)
                    .frame(width: d * 0.105, height: d * 0.105)
                    .offset(x: d * 0.664 - d * 0.0525, y: d * 0.336 - d * 0.0525)
            }
            .frame(width: d, height: d)
        }
    }
}
