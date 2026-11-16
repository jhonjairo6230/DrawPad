import Foundation

/// Mueve o cambia de tamaño un elemento de la hoja.
struct MoveElementUseCase {
    private let elements: PageElementRepository

    init(elements: PageElementRepository) {
        self.elements = elements
    }

    /// Guarda la posición nueva, corregida para que el elemento no se salga
    /// por arriba ni por la izquierda y no quede demasiado pequeño para tocarlo.
    /// - Throws: ``DrawingError/elementNotFound`` si ya no existe.
    func execute(id: UUID, frame: CGRect) throws -> PageElement {
        guard var element = try elements.findElement(id: id) else {
            throw DrawingError.elementNotFound
        }
        element.frame = Self.corrected(frame)
        try elements.save(element)
        return element
    }

    static func corrected(_ frame: CGRect) -> CGRect {
        CGRect(
            x: max(0, frame.origin.x),
            y: max(0, frame.origin.y),
            width: max(PageElementLayout.minimumSide, frame.width),
            // Un texto de una línea mide menos que el mínimo de ancho; el
            // alto solo se corrige para que no sea cero o negativo.
            height: max(1, frame.height)
        )
    }
}
