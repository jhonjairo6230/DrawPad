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
        for element in elements {
            switch element.content {
            case .text(let text):
                let rect = CGRect(
                    origin: element.frame.origin,
                    size: CGSize(width: element.frame.width, height: height(of: text, width: element.frame.width))
                )
                (text as NSString).draw(
                    with: rect,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes(for: theme),
                    context: nil
                )
            case .image(let data):
                UIImage(data: data)?.draw(in: element.frame)
            }
        }
    }
}
