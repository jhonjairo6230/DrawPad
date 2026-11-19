import Foundation

/// Gira una figura un cuarto de vuelta (90°) en el sentido de las agujas del
/// reloj, alrededor de su centro.
///
/// El marco intercambia ancho y alto: un cilindro de 110 × 140 de pie pasa a
/// 140 × 110 acostado. Las conexiones la siguen solas, porque se dibujan a
/// partir del marco.
struct RotateShapeUseCase {
    private let elements: PageElementRepository

    init(elements: PageElementRepository) {
        self.elements = elements
    }

    /// - Throws: ``DrawingError/elementNotFound`` si no existe o no es una figura.
    func execute(id: UUID) throws -> PageElement {
        guard var element = try elements.findElement(id: id),
              case .shape(var shape) = element.content else {
            throw DrawingError.elementNotFound
        }
        shape.quarterTurns = (shape.quarterTurns + 1) % 4
        element.content = .shape(shape)
        element.frame = MoveElementUseCase.corrected(Self.turned(element.frame))
        try elements.save(element)
        return element
    }

    /// El mismo centro con ancho y alto intercambiados.
    static func turned(_ frame: CGRect) -> CGRect {
        CGRect(
            x: frame.midX - frame.height / 2,
            y: frame.midY - frame.width / 2,
            width: frame.height,
            height: frame.width
        )
    }
}
