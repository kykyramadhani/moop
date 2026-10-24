import ImageIO
import UIKit

extension UIImage {
    func squareCropped() -> UIImage {
        let side = min(size.width, size.height)
        return cropped(to: CGRect(x: (size.width - side) / 2,
                                  y: (size.height - side) / 2,
                                  width: side, height: side))
    }

    // rect is in the point space of the photo as you see it, rotation already
    // applied. the pixels come straight out of the original, so a crop never
    // costs resolution.
    func cropped(to rect: CGRect) -> UIImage {
        let flat = upright()
        guard let source = flat.cgImage else { return flat }
        let bounds = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        let pixels = CGRect(x: rect.minX * flat.scale, y: rect.minY * flat.scale,
                            width: rect.width * flat.scale, height: rect.height * flat.scale)
            .integral.intersection(bounds)
        guard !pixels.isEmpty, let cut = source.cropping(to: pixels) else { return flat }
        return UIImage(cgImage: cut, scale: flat.scale, orientation: .up)
    }

    // library photos keep their rotation in metadata, so a crop rect would
    // land on the wrong side of a portrait shot. bake it into the pixels once.
    func upright() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format)
            .image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }

    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
