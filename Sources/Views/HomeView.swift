import PhotosUI
import SwiftUI

struct HomeView: View {
    @State var model: HomeViewModel
    @Environment(\.scenePhase) private var phase

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            viewfinder
            Spacer()
            controls
            Spacer()
        }
        .background(Color.viewfinder)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .photosPicker(isPresented: $model.showingPicker, selection: $model.picked, matching: .images)
        .onChange(of: model.picked) { _, item in
            guard let item else { return }
            Task { await model.load(item) }
        }
        .task { await model.appeared() }
        // coming back from the background is exactly when the evening has turned,
        // and .task does not run again for that
        .onChange(of: phase) { _, new in if new == .active { model.becameActive() } }
        .onDisappear { model.disappeared() }
        .alert(StreakReminder.title,
               isPresented: Binding(get: { model.reminder != nil },
                                    set: { if !$0 { model.dismissReminder() } }),
               presenting: model.reminder) { _ in
            Button("Not tonight", role: .cancel) {}
            Button("Snap now") {}.keyboardShortcut(.defaultAction)
        } message: { due in
            Text(due.message)
        }
        .alert(model.block?.title ?? "", isPresented: $model.showingBlock, presenting: model.block) { block in
            if block.canOpenSettings {
                Button("Not now", role: .cancel) {}
                Button("Open Settings") { openAppSettings() }.keyboardShortcut(.defaultAction)
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: { block in
            Text(block.message)
        }
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            LensMark(tint: .brandText).frame(width: 28, height: 28)
            Spacer()
            Button(action: model.openHistory) {
                barIcon("square.grid.2x2")
            }
            Button(action: model.openSettings) {
                barIcon("gearshape")
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 54)
    }

    private func barIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 22))
            .foregroundStyle(Color.onDark.opacity(0.85))
            .frame(width: 44, height: 44)
    }

    private var viewfinder: some View {
        ZStack {
            if let frozen = model.frozenPhoto {
                Image(uiImage: frozen).resizable().scaledToFill()
            } else if model.cameraDenied {
                Color.white.opacity(0.06)
            } else {
                CameraPreview(session: model.camera.session)
            }
            if !model.isLive { Color.viewfinder.opacity(0.55) }
            if let note = model.note { message(note) }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(alignment: .topLeading) { if model.isLive { flashChip.padding(8) } }
        .overlay(alignment: .topTrailing) { if model.isLive { zoomChip.padding(8) } }
        .gesture(
            MagnifyGesture()
                .onChanged { model.pinch($0.magnification) }
                .onEnded { _ in model.pinchEnded() }
        )
        .padding(.horizontal, 20)
    }

    private func message(_ note: String) -> some View {
        VStack(spacing: 16) {
            Text(note)
                .font(.bodyLarge)
                .tracking(-0.4)
                .foregroundStyle(Color.onDark.opacity(0.8))
                .multilineTextAlignment(.center)
            // the only way out of this state, inside the state itself
            if model.cameraDenied {
                Button("Open Settings", action: openAppSettings)
                    .buttonStyle(ViewfinderButtonStyle())
            }
        }
        .frame(width: 322)
    }

    private var flashChip: some View {
        Button(action: model.toggleFlash) {
            CameraChip(filled: model.flashOn) {
                Image(systemName: model.flashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(model.flashOn ? Color.viewfinder : Color.onDark)
            }
        }
    }

    private var zoomChip: some View {
        Button(action: model.cycleZoom) {
            CameraChip {
                Text(model.zoomLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.onDark)
            }
        }
    }

    private var controls: some View {
        HStack {
            Button(action: model.openPicker) {
                barIcon("photo").foregroundStyle(Color.onDark)
            }
            .opacity(model.libraryDimmed ? 0.3 : 0.8)
            .disabled(model.libraryDimmed)

            Spacer()

            if model.isWorking {
                ProgressRing().frame(width: 74, height: 74)
            } else {
                ShutterButton(action: model.shoot)
                    .opacity(model.cameraDimmed ? 0.3 : 1)
            }

            Spacer()

            Button(action: model.flip) {
                barIcon("arrow.triangle.2.circlepath").foregroundStyle(Color.onDark)
            }
            .opacity(model.cameraDimmed ? 0.3 : 0.8)
            .disabled(model.cameraDimmed)
        }
        .padding(.horizontal, 52)
    }
}
