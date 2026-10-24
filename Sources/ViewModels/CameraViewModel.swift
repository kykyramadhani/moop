import PhotosUI
import SwiftUI

@Observable
final class CameraViewModel {
    let camera = CameraSession()
    let reader: MoodReader
    private let snaps: SnapStore

    var showingPicker = false
    var picked: PhotosPickerItem?
    /// the photo waiting to be read, shown on the review screen
    var pending: UIImage?
    /// a library photo still being squared off, shown on the crop screen
    var cropping: UIImage?
    var finished = false

    init(reader: MoodReader, snaps: SnapStore) {
        self.reader = reader
        self.snaps = snaps
    }

    var denied: Bool { camera.denied }
    var stops: [CGFloat] { camera.stops }
    var zoom: CGFloat { camera.zoom }
    var isReading: Bool { reader.isWorking }

    func start() async { await camera.start() }
    func stop() { camera.stop() }
    func flip() { camera.flip() }
    func setZoom(_ v: CGFloat) { camera.setZoom(v) }
    func openLibrary() { showingPicker = true }

    func shoot() {
        camera.capture { [weak self] image in
            Task { @MainActor in self?.pending = image }
        }
    }

    // a library photo is any shape, so the person chooses the square rather
    // than having the middle taken for them.
    func load(_ item: PhotosPickerItem) async {
        defer { picked = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        cropping = image.upright()
    }

    func useCrop(_ image: UIImage) {
        cropping = nil
        pending = image
    }

    func cancelCrop() { cropping = nil }

    func discard() { pending = nil }

    // the photo the user accepted is the one that gets read and the one that
    // gets saved. nothing re-crops or re-encodes it in between.
    func readPending() async {
        guard let photo = pending else { return }
        await reader.read(photo)
        if let result = reader.result {
            snaps.add(image: result.photo, mood: result.mood,
                      sentence: result.sentence, because: result.because)
        }
        finished = true
    }

    // the reader is optional. a photo kept without a word is still a record.
    func keepWithoutReading() {
        guard let photo = pending else { return }
        snaps.add(image: photo, mood: nil, sentence: nil)
        reader.reset()
        finished = true
    }
}
