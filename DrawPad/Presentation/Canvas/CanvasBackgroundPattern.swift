import UIKit

/// Dibuja los papeles de fondo (cuadrícula, líneas, puntos).
///
/// Cada papel es una baldosa pequeña que UIKit repite (`UIColor(patternImage:)`).
/// Así el mismo "color" sirve para pintar el fondo en pantalla y para
/// rellenar la imagen al exportar.
enum CanvasBackgroundPattern {
    /// Separación entre líneas o puntos, en puntos de pantalla.
    static let spacing: CGFloat = 32

    private static let inkColor = UIColor(red: 0.72, green: 0.78, blue: 0.88, alpha: 1)

    static func color(for background: CanvasBackground) -> UIColor {
        guard background != .blank else { return .white }
        return UIColor(patternImage: tile(for: background))
    }

    /// Una baldosa de `spacing` × `spacing` con el dibujo del papel.
    static func tile(for background: CanvasBackground) -> UIImage {
        let size = CGSize(width: spacing, height: spacing)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            inkColor.setFill()

            let line: CGFloat = 1
            switch background {
            case .blank:
                break
            case .lines:
                context.fill(CGRect(x: 0, y: spacing - line, width: spacing, height: line))
            case .grid:
                context.fill(CGRect(x: 0, y: spacing - line, width: spacing, height: line))
                context.fill(CGRect(x: spacing - line, y: 0, width: line, height: spacing))
            case .dots:
                let dot: CGFloat = 3
                let origin = (spacing - dot) / 2
                context.cgContext.fillEllipse(in: CGRect(x: origin, y: origin, width: dot, height: dot))
            }
        }
    }
}
