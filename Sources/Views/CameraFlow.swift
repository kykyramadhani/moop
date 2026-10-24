import PhotosUI
import SwiftUI

// camera, crop, review, reading and result are one journey, so they live in
// one full screen cover rather than five pushes.
struct CameraFlow: View {
    @State var model: CameraViewModel
    let reader: MoodReader
    let snaps: SnapStore
    var close: (Bool) -> Void

    var body: some View {
        ZStack {
            if reader.isFailed {
                ResultView(model: ResultViewModel(reader: reader, snaps: snaps),
                           keepWithout: model.keepWithoutReading,
                           done: { close(false) })
            } else if model.isReading {
                ReadingView(photo: model.pending)
            } else if let photo = model.pending {
                ReviewView(photo: photo,
                           read: { Task { await model.readPending() } },
                           keep: { model.keepWithoutReading() },
                           back: model.discard)
            } else if let raw = model.cropping {
                CropView(photo: raw, cancel: model.cancelCrop, confirm: model.useCrop)
            } else {
                CameraView(model: model, close: { close(false) })
            }
        }
        .photosPicker(isPresented: $model.showingPicker, selection: $model.picked, matching: .images)
        .onChange(of: model.picked) { _, item in
            guard let item else { return }
            Task { await model.load(item) }
        }
        .task { await model.start() }
        .onChange(of: model.finished) { _, done in if done { close(reader.result != nil) } }
        .onDisappear { model.stop() }
    }
}

struct CameraView: View {
    @State var model: CameraViewModel
    var close: () -> Void

    var body: some View {
        ZStack {
            Moop.pureBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: Space.beat)
                viewfinder
                Spacer(minLength: Space.beat)
                if !model.denied && model.stops.count > 1 {
                    ZoomPicker(stops: model.stops, current: model.zoom, pick: model.setZoom)
                        .padding(.bottom, Space.beat)
                }
                controls
            }
        }
        .preferredColorScheme(.dark)
    }

    // square, because a square is what gets saved. the person frames the
    // picture they end up with rather than a wider one that loses its edges.
    private var viewfinder: some View {
        Group {
            if model.denied {
                Color.white.opacity(0.06).overlay { deniedState }
            } else {
                CameraPreview(session: model.camera.session)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
    }

    private var topBar: some View {
        HStack {
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close camera")
            Spacer()
            Text("moop.")
                .font(MoopType.title)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Space.beat)
    }

    private var controls: some View {
        HStack {
            cameraButton("photo.on.rectangle", "Library", action: model.openLibrary)
            Spacer()
            ShutterButton(action: model.shoot)
                .opacity(model.denied ? 0.3 : 1)
                .disabled(model.denied)
            Spacer()
            cameraButton("arrow.triangle.2.circlepath.camera", "Flip", action: model.flip)
                .opacity(model.denied ? 0.3 : 1)
                .disabled(model.denied)
        }
        .padding(.horizontal, Space.section)
        .padding(.bottom, Space.beat)
        .frame(height: 120)
        .background(Moop.pureBlack)
    }

    private func cameraButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Space.dot) {
                Image(systemName: icon).font(.system(size: 22))
                Text(label).font(MoopType.micro)
            }
            .foregroundStyle(.white)
            .frame(width: 64, height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var deniedState: some View {
        VStack(spacing: Space.beat) {
            Text("moop cannot see anything yet.")
                .font(MoopType.line)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("Camera access is off. You can still pick a photo from your library.")
                .font(MoopType.reading)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
            Button("Open Settings", action: openAppSettings)
                .font(MoopType.statement)
                .foregroundStyle(Moop.onAccent)
                .padding(.horizontal, Space.gutter)
                .frame(height: 46)
                .background(Moop.citrus, in: Capsule())
        }
        .padding(Space.beat)
    }
}

struct ReviewView: View {
    let photo: UIImage
    var read: () -> Void
    var keep: () -> Void
    var back: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MoopHeader(trailing: "review")
                .padding(.top, Space.cut)

            Text("Keep this one?")
                .font(MoopType.poster)
                .foregroundStyle(Moop.ink)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            PhotoCard(image: photo)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            Text(Date.now.formatted(.dateTime.day().month(.abbreviated)).uppercased()
                 + " · " + Date.now.formatted(.dateTime.hour().minute()))
                .font(MoopType.detail)
                .foregroundStyle(Moop.ink.opacity(0.7))
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            Text("Your photo is read right here. Nothing is uploaded.")
                .font(MoopType.reading)
                .foregroundStyle(Moop.ink.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.cut)

            Spacer(minLength: Space.beat)

            MoopAction(title: "find its feeling", action: read)
                .padding(.horizontal, Space.gutter)

            Button("‹  choose another", action: back)
                .font(MoopType.reading)
                .foregroundStyle(Moop.violet)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)
                .padding(.bottom, Space.scene)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Moop.canvas)
    }
}

struct ReadingView: View {
    let photo: UIImage?
    @State private var travelling = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MoopHeader()
                .padding(.top, Space.cut)

            Text("Finding the feeling.")
                .font(MoopType.poster)
                .foregroundStyle(Moop.ink)
                // one line in the design. the stand-in serif runs wider, so it
                // shrinks to fit rather than losing its last word.
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            PhotoCard(image: photo)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            Spacer(minLength: Space.beat)

            Text("A gentle on-device read…")
                .font(MoopType.statement)
                .foregroundStyle(Moop.ink)
                .padding(.horizontal, Space.gutter)

            Text("This can be wrong. Your photo is yours either way.")
                .font(MoopType.detail)
                .foregroundStyle(Moop.ink.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.cut)

            track
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)
                .padding(.bottom, Space.scene)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Moop.canvas)
        .onAppear { travelling = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reading your photo on this iPhone")
    }

    // ponytail: the model reports no progress, so a filling bar would be a lie.
    // a shuttle says "working" without claiming to know how far along it is.
    private var track: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Moop.veil)
                Capsule()
                    .fill(Moop.violet)
                    .frame(width: w * 0.32)
                    .offset(x: travelling ? w * 0.68 : 0)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                               value: travelling)
            }
        }
        .frame(height: 4)
    }
}
