import UIKit

/// Lee el portapapeles del sistema (`UIPasteboard`).
///
/// Si hay imagen y texto a la vez, gana la imagen. Las imágenes grandes se
/// reducen antes de guardarlas: una foto a tamaño completo ocupa decenas de
/// megas y en la hoja se ve a una fracción de ese tamaño.
///
/// iOS puede mostrar un aviso de permiso ("permitir pegar") la primera vez
/// que una app lee el portapapeles; es del sistema y no se puede evitar aquí.
final class SystemClipboard: Clipboard {
    /// Lado más largo, en píxeles, de una imagen pegada.
    static let maxPixelSide: CGFloat = 2048

    func content() -> ClipboardContent? {
        let pasteboard = UIPasteboard.general
        if pasteboard.hasImages, let image = pasteboard.image {
            let prepared = Self.downscaled(image)
            if let data = prepared.pngData() {
                return .image(data: data, size: prepared.size)
            }
        }
        if pasteboard.hasStrings, let text = pasteboard.string, !text.isEmpty {
            return .text(text)
        }
        return nil
    }

    /// La imagen a escala 1 (un píxel por punto) y, si hace falta, reducida.
    private static func downscaled(_ image: UIImage) -> UIImage {
        let pixelSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let longestSide = max(pixelSize.width, pixelSize.height)
        guard longestSide > 0 else { return image }
        let factor = min(1, maxPixelSide / longestSide)
        let target = CGSize(width: pixelSize.width * factor, height: pixelSize.height * factor)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
