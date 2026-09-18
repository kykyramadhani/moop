import AVFoundation
import SwiftUI

// the viewfinder is square, so every capture is centre-cropped to 1:1. what
// you framed is what gets read.
@Observable
final class CameraSession: NSObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var position: AVCaptureDevice.Position = .back
    private var onCapture: ((UIImage) -> Void)?
    private var device: AVCaptureDevice?
    // on a multi-lens device, factor 1.0 is the ultra-wide. this is the factor
    // that means 1x to a person, so every ui number is relative to it.
    private var baseFactor: CGFloat = 1

    var denied = false
    var flashOn = false
    private(set) var zoom: CGFloat = 1
    private(set) var minZoom: CGFloat = 1
    private(set) var maxZoom: CGFloat = 5
    // the stops this device really has. a single-lens camera has one, so a tap
    // does nothing and the chip just reports the pinch.
    private(set) var stops: [CGFloat] = [1]

    var zoomLabel: String {
        let rounded = (zoom * 10).rounded() / 10
        return rounded == rounded.rounded()
            ? "\(Int(rounded))×"
            : String(format: "%.1f×", rounded)
    }

    func cycleZoom() {
        guard stops.count > 1 else { return }
        let next = stops.first { $0 > zoom + 0.05 } ?? stops[0]
        setZoom(next)
    }

    func start() async {
        guard await authorised() else { denied = true; return }
        guard session.inputs.isEmpty else { resume(); return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        attachInput()
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        // attachInput only records that 1x is wanted. the hardware sits on the
        // ultra-wide until someone writes it.
        setZoom(1)
        resume()
    }

    func flip() {
        position = position == .back ? .front : .back
        session.beginConfiguration()
        session.inputs.forEach(session.removeInput)
        attachInput()
        session.commitConfiguration()
        setZoom(1)
    }

    func setZoom(_ wanted: CGFloat) {
        guard let device else { return }
        let ui = min(max(wanted, minZoom), maxZoom)
        let factor = min(max(ui * baseFactor, device.minAvailableVideoZoomFactor),
                         device.maxAvailableVideoZoomFactor)
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = factor
            device.unlockForConfiguration()
            zoom = ui
        } catch {
            print("[moop] zoom refused: \(error.localizedDescription)")
        }
    }

    func capture(_ handler: @escaping (UIImage) -> Void) {
        onCapture = handler
        let settings = AVCapturePhotoSettings()
        if output.supportedFlashModes.contains(.on) {
            settings.flashMode = flashOn ? .on : .off
        }
        output.capturePhoto(with: settings, delegate: self)
    }

    func stop() {
        guard session.isRunning else { return }
        Task.detached { [session] in session.stopRunning() }
    }

    private func attachInput() {
        // prefer a virtual device, otherwise there is no 0.5x to offer
        let types: [AVCaptureDevice.DeviceType] = [.builtInTripleCamera,
                                                   .builtInDualWideCamera,
                                                   .builtInWideAngleCamera]
        let wanted = position
        let found = types.lazy.compactMap {
            AVCaptureDevice.default($0, for: .video, position: wanted)
        }.first
        guard let found,
              let input = try? AVCaptureDeviceInput(device: found),
              session.canAddInput(input) else { return }
        session.addInput(input)
        device = found
        baseFactor = found.virtualDeviceSwitchOverVideoZoomFactors.first.map { CGFloat($0.doubleValue) } ?? 1
        minZoom = found.minAvailableVideoZoomFactor / baseFactor
        maxZoom = min(found.maxAvailableVideoZoomFactor / baseFactor, 8)
        // switch-over points are where the hardware changes lens, which is
        // exactly where a person expects the tap to land
        let switches = found.virtualDeviceSwitchOverVideoZoomFactors
            .map { CGFloat($0.doubleValue) / baseFactor }
        stops = ([minZoom, 1] + switches.dropFirst())
            .filter { $0 >= minZoom && $0 <= maxZoom }
            .reduce(into: [CGFloat]()) { list, value in
                if !list.contains(where: { abs($0 - value) < 0.05 }) { list.append(value) }
            }
            .sorted()
        zoom = 1
    }

    private func resume() {
        guard !session.isRunning else { return }
        Task.detached { [session] in session.startRunning() }
    }

    private func authorised() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: true
        case .notDetermined: await AVCaptureDevice.requestAccess(for: .video)
        default: false
        }
    }
}

extension CameraSession: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        let square = image.squareCropped()
        Task { @MainActor in onCapture?(square) }
    }
}
