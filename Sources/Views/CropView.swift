import SwiftUI

// a square window over a photo from the library. drag to move it, pinch to
// zoom, and what sits inside the window is exactly what gets saved.
struct CropView: View {
    let photo: UIImage
    var cancel: () -> Void
    var confirm: (UIImage) -> Void

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var side: CGFloat = 0
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var slide: CGSize = .zero

    private let widest: CGFloat = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MoopHeader(trailing: "crop")
                .padding(.top, Space.cut)

            Text("Pick the square.")
                .font(MoopType.poster)
                .foregroundStyle(Moop.ink)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            window
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            Text("Drag to move, pinch to zoom. moop keeps every photo square so your days line up.")
                .font(MoopType.detail)
                .foregroundStyle(Moop.ink.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            Spacer(minLength: Space.beat)

            MoopAction(title: "use this square") { confirm(cut()) }
                .padding(.horizontal, Space.gutter)

            Button("choose another", action: cancel)
                .font(MoopType.reading)
                .foregroundStyle(Moop.violet)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)
                .padding(.bottom, Space.scene)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Moop.canvas)
    }

    private var window: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let edge = geo.size.width
                    let live = min(max(scale * pinch, 1), widest)
                    let bound = headroom(live, in: edge)
                    let shift = CGSize(
                        width: min(max(offset.width + slide.width, -bound.width), bound.width),
                        height: min(max(offset.height + slide.height, -bound.height), bound.height))
                    Image(uiImage: photo)
                        .resizable()
                        .frame(width: photo.size.width * fit(edge) * live,
                               height: photo.size.height * fit(edge) * live)
                        .offset(shift)
                        .frame(width: edge, height: edge)
                        .onAppear { side = edge }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
            .gesture(drag.simultaneously(with: zoom))
            .accessibilityLabel("Square crop. Drag to move, pinch to zoom.")
    }

    private var drag: some Gesture {
        DragGesture()
            .updating($slide) { value, state, _ in state = value.translation }
            .onEnded { value in
                let bound = headroom(scale, in: side)
                offset = CGSize(
                    width: min(max(offset.width + value.translation.width, -bound.width), bound.width),
                    height: min(max(offset.height + value.translation.height, -bound.height), bound.height))
            }
    }

    private var zoom: some Gesture {
        MagnifyGesture()
            .updating($pinch) { value, state, _ in state = value.magnification }
            .onEnded { value in
                scale = min(max(scale * value.magnification, 1), widest)
                let bound = headroom(scale, in: side)
                offset = CGSize(width: min(max(offset.width, -bound.width), bound.width),
                                height: min(max(offset.height, -bound.height), bound.height))
            }
    }

    // the scale at which the photo's shorter edge exactly fills the window
    private func fit(_ edge: CGFloat) -> CGFloat {
        edge / max(min(photo.size.width, photo.size.height), 1)
    }

    // how far the photo may slide before the window would show nothing
    private func headroom(_ live: CGFloat, in edge: CGFloat) -> CGSize {
        let grown = CGSize(width: photo.size.width * fit(edge) * live,
                           height: photo.size.height * fit(edge) * live)
        return CGSize(width: max((grown.width - edge) / 2, 0),
                      height: max((grown.height - edge) / 2, 0))
    }

    private func cut() -> UIImage {
        guard side > 0 else { return photo.squareCropped() }
        let perPoint = fit(side) * scale
        let span = side / perPoint
        return photo.cropped(to: CGRect(
            x: (photo.size.width - span) / 2 - offset.width / perPoint,
            y: (photo.size.height - span) / 2 - offset.height / perPoint,
            width: span, height: span))
    }
}
