import UIKit

/// Aspecto de los textos de una hoja y cómo se dibujan los elementos en una
/// imagen. Lo comparten la capa que los muestra en pantalla
/// (``PageElementsLayer``) y la exportación, para que coincidan.
enum PageElementStyle {
    static let font = UIFont.systemFont(ofSize: 20)

    /// Tinta del texto: oscura sobre papel claro y clara sobre papel oscuro.
    static func textColor(for theme: CanvasTheme) -> UIColor {
        switch theme {
        case .light: return UIColor(white: 0.1, alpha: 1)
        case .dark: return UIColor(white: 0.95, alpha: 1)
        }
    }

    static func attributes(for theme: CanvasTheme) -> [NSAttributedString.Key: Any] {
        [.font: font, .foregroundColor: textColor(for: theme)]
    }

    /// Alto que ocupa un texto con ese ancho.
    static func height(of text: String, width: CGFloat) -> CGFloat {
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(bounds.height)
    }

    /// Dibuja los elementos en el contexto gráfico actual, del fondo hacia
    /// arriba. Se usa al exportar la hoja como imagen o PDF.
    static func draw(_ elements: [PageElement], theme: CanvasTheme) {
        // Primero las conexiones, para que las figuras queden por encima.
        DiagramRenderer.draw(
            DiagramGeometry.segments(for: elements, frames: displayFrames(of: elements)),
            theme: theme
        )
        for element in elements {
            switch element.content {
            case .text(let text):
                (text as NSString).draw(
                    with: displayFrame(of: element),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes(for: theme),
                    context: nil
                )
            case .image(let data):
                UIImage(data: data)?.draw(in: element.frame)
            case .shape(let shape):
                DiagramRenderer.draw(shape, in: element.frame, theme: theme)
            case .mermaid(let diagram):
                UIImage(data: diagram.image)?.draw(in: element.frame)
            case .connector:
                break // Ya dibujadas arriba.
            }
        }
    }

    /// El marco que ocupa un elemento en pantalla: en un texto, con el alto
    /// real de su contenido; en el resto, el guardado.
    static func displayFrame(of element: PageElement) -> CGRect {
        guard case .text(let text) = element.content else { return element.frame }
        var frame = element.frame
        frame.size.height = height(of: text, width: frame.width)
        return frame
    }

    /// El marco visible de cada elemento que no es una conexión.
    static func displayFrames(of elements: [PageElement]) -> [UUID: CGRect] {
        var frames: [UUID: CGRect] = [:]
        for element in elements where !element.isConnector {
            frames[element.id] = displayFrame(of: element)
        }
        return frames
    }
}
