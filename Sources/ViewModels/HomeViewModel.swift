import PhotosUI
import SwiftUI

@Observable
final class HomeViewModel {
    let camera = CameraSession()
    let reader: MoodReader

    private let snaps: SnapStore
    private let navigator: Navigator
    private var pinchStart: CGFloat = 1

    var showingPicker = false
    var picked: PhotosPickerItem?
    var reminder: StreakReminder?
    var showingBlock = false

    init(reader: MoodReader, snaps: SnapStore, navigator: Navigator) {
        self.reader = reader
        self.snaps = snaps
        self.navigator = navigator
    }

    // MARK: what the screen shows

    // once the shutter fires the frame is held, so the photo being read is the
    // photo on screen
    var frozenPhoto: UIImage? {
        guard let photo = reader.lastPhoto, reader.isWorking || reader.isFailed else { return nil }
        return photo
    }

    var block: Block? { reader.block }
    var isWorking: Bool { reader.isWorking }
    var cameraDenied: Bool { camera.denied }
    var flashOn: Bool { camera.flashOn }
    var zoomLabel: String { camera.zoomLabel }

    var note: String? {
        if camera.denied { return "Camera access is off." }
        if reader.isWorking { return "Reading the moop…" }
        return reader.failure
    }

    // flash and zoom control a live camera. they go when the frame is held, and
    // when there is no camera to control.
    var isLive: Bool {
        !camera.denied && (reader.lastPhoto == nil || !(reader.isWorking || reader.isFailed))
    }

    var libraryDimmed: Bool { reader.isWorking || block != nil }
    // the library still works without a camera, so only the camera controls go
    var cameraDimmed: Bool { libraryDimmed || camera.denied }

    // MARK: lifecycle

    func appeared() async {
        reader.checkAvailability()
        showingBlock = block != nil
        // before the camera, which waits on the permission sheet on first run
        refreshReminder()
        await camera.start()
    }

    func becameActive() { refreshReminder() }
    func disappeared() { camera.stop() }

    private func refreshReminder() {
        reminder = StreakReminder.due(streak: snaps.streak,
                                      snappedToday: !snaps.snaps(on: .now).isEmpty)
    }

    // MARK: actions

    func dismissReminder() { reminder = nil }
    func openHistory() { navigator.go(.history) }
    func openSettings() { navigator.go(.settings) }
    func toggleFlash() { camera.flashOn.toggle() }
    func flip() { camera.flip() }
    func openPicker() { showingPicker = true }

    func cycleZoom() {
        camera.cycleZoom()
        pinchStart = camera.zoom
    }

    func pinch(_ magnification: CGFloat) {
        guard isLive else { return }
        camera.setZoom(pinchStart * magnification)
    }

    func pinchEnded() { pinchStart = camera.zoom }

    func shoot() {
        if block != nil { showingBlock = true; return }
        if reader.canRetry {
            Task { await reader.retry(); finish() }
            return
        }
        camera.capture { [weak self] image in
            Task { await self?.read(image) }
        }
    }

    func load(_ item: PhotosPickerItem) async {
        defer { picked = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await read(image.squareCropped())
    }

    private func read(_ image: UIImage) async {
        await reader.read(image)
        finish()
    }

    private func finish() {
        guard let result = reader.result else { return }
        snaps.add(image: result.photo, mood: result.mood, sentence: result.sentence)
        navigator.go(.result)
    }
}
