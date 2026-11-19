import CoreGraphics

/// Las cuentas del lienzo con zoom, separadas de UIKit para poder probarlas.
///
/// Hay dos sistemas de coordenadas:
/// - **Dibujo:** en el que PencilKit guarda los trazos. No cambia con el zoom.
/// - **Pantalla:** lo que se ve. Un punto del dibujo `p` aparece en
///   `p × zoom − desplazamiento`.
enum CanvasGeometry {
    static let minimumZoom: CGFloat = 1
    static let maximumZoom: CGFloat = 4

    /// Tamaño de la hoja, en coordenadas de dibujo: como mínimo lo que cabe en
    /// pantalla y, si hay contenido más allá (por ejemplo, tras girar el iPad),
    /// lo necesario para poder llegar hasta él.
    /// - Parameter drawingBounds: rectángulo que ocupa todo el contenido de
    ///   la hoja (trazos, textos e imágenes); `nil` si está vacía.
    static func pageSize(viewport: CGSize, drawingBounds: CGRect?) -> CGSize {
        guard let bounds = drawingBounds, !bounds.isNull, !bounds.isInfinite else { return viewport }
        return CGSize(
            width: max(viewport.width, bounds.maxX),
            height: max(viewport.height, bounds.maxY)
        )
    }

    /// Tamaño del contenido desplazable: la hoja ampliada por el zoom.
    static func contentSize(pageSize: CGSize, zoomScale: CGFloat) -> CGSize {
        CGSize(width: pageSize.width * zoomScale, height: pageSize.height * zoomScale)
    }

    /// El zoom con el que una hoja cabe a lo ancho en la pantalla, sin
    /// ampliar nunca (como mucho 1). Para leer en el iPhone una hoja hecha en
    /// el iPad.
    static func fitWidthZoom(viewport: CGSize, pageSize: CGSize) -> CGFloat {
        guard viewport.width > 0, pageSize.width > 0 else { return 1 }
        return min(1, viewport.width / pageSize.width)
    }

    /// El punto de la hoja que se ve en el centro de la pantalla: ahí se
    /// colocan los textos e imágenes nuevos.
    static func visibleCenter(viewport: CGSize, zoomScale: CGFloat, contentOffset: CGPoint) -> CGPoint {
        guard zoomScale > 0 else { return CGPoint(x: viewport.width / 2, y: viewport.height / 2) }
        return CGPoint(
            x: (contentOffset.x + viewport.width / 2) / zoomScale,
            y: (contentOffset.y + viewport.height / 2) / zoomScale
        )
    }

    /// El rectángulo que abarca los trazos y los elementos; `nil` si no hay nada.
    static func contentBounds(strokes: CGRect?, elements: [CGRect]) -> CGRect? {
        let all = ([strokes].compactMap { $0 } + elements).filter { !$0.isNull && !$0.isInfinite }
        guard let first = all.first else { return nil }
        return all.dropFirst().reduce(first) { $0.union($1) }
    }

    /// Dónde va el centro del papel, en pantalla, para que acompañe a los
    /// trazos al ampliar y desplazar.
    static func paperCenter(pageSize: CGSize, zoomScale: CGFloat, contentOffset: CGPoint) -> CGPoint {
        CGPoint(
            x: pageSize.width * zoomScale / 2 - contentOffset.x,
            y: pageSize.height * zoomScale / 2 - contentOffset.y
        )
    }
}
