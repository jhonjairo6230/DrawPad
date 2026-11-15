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
    /// pantalla y, si hay trazos más allá (por ejemplo, tras girar el iPad),
    /// lo necesario para poder llegar hasta ellos.
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

    /// Dónde va el centro del papel, en pantalla, para que acompañe a los
    /// trazos al ampliar y desplazar.
    static func paperCenter(pageSize: CGSize, zoomScale: CGFloat, contentOffset: CGPoint) -> CGPoint {
        CGPoint(
            x: pageSize.width * zoomScale / 2 - contentOffset.x,
            y: pageSize.height * zoomScale / 2 - contentOffset.y
        )
    }
}
