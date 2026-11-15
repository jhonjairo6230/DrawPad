import UIKit

/// Dibuja los papeles de fondo (cuadrícula, líneas, puntos), claros u oscuros.
///
/// Cada papel es una baldosa pequeña que UIKit repite (`UIColor(patternImage:)`).
/// Así el mismo "color" sirve para pintar el fondo en pantalla y para
/// rellenar la imagen al exportar.
enum CanvasBackgroundPattern {
    /// Separación entre líneas o puntos, en puntos de pantalla.
    static let spacing: CGFloat = 32

    /// Color liso del papel.
    static func paperColor(for theme: CanvasTheme) -> UIColor {
        switch theme {
        case .light: return .white
        case .dark: return UIColor(white: 0.11, alpha: 1)
        }
    }

    /// Color de las líneas y los puntos: visible, pero sin competir con la tinta.
    static func ruleColor(for theme: CanvasTheme) -> UIColor {
        switch theme {
        case .light: return UIColor(red: 0.72, green: 0.78, blue: 0.88, alpha: 1)
        case .dark: return UIColor(white: 0.27, alpha: 1)
        }
    }

    static func color(for background: CanvasBackground, theme: CanvasTheme) -> UIColor {
        guard background != .blank else { return paperColor(for: theme) }
        return UIColor(patternImage: tile(for: background, theme: theme))
    }

    /// Una baldosa de `spacing` × `spacing` con el dibujo del papel.
    static func tile(for background: CanvasBackground, theme: CanvasTheme) -> UIImage {
        let size = CGSize(width: spacing, height: spacing)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            paperColor(for: theme).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            ruleColor(for: theme).setFill()

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
