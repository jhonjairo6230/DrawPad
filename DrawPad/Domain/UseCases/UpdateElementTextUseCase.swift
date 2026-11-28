import Foundation

/// Cambia el texto de un cuadro de texto, o el texto dentro de una figura.
struct UpdateElementTextUseCase {
    private let elements: PageElementRepository

    init(elements: PageElementRepository) {
        self.elements = elements
    }

    /// Un cuadro de texto no puede quedar vacío; una figura sí (se queda sin
    /// texto).
    /// - Throws: ``DrawingError/emptyText`` si un cuadro de texto queda vacío,
    ///   o ``DrawingError/elementNotFound`` si no existe o no lleva texto.
    func execute(id: UUID, text: String) throws -> PageElement {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var element = try elements.findElement(id: id) else {
            throw DrawingError.elementNotFound
        }
        switch element.content {
        case .text:
            guard !trimmed.isEmpty else { throw DrawingError.emptyText }
            element.content = .text(trimmed)
        case .shape(var shape):
            shape.label = trimmed
            element.content = .shape(shape)
        case .image, .connector, .mermaid:
            throw DrawingError.elementNotFound
        }
        try elements.save(element)
        return element
    }
}
