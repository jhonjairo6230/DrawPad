import Foundation

/// Cambia el texto de un cuadro de texto ya colocado.
struct UpdateElementTextUseCase {
    private let elements: PageElementRepository

    init(elements: PageElementRepository) {
        self.elements = elements
    }

    /// - Throws: ``DrawingError/emptyText`` si el texto queda vacío, o
    ///   ``DrawingError/elementNotFound`` si no existe o no es un texto.
    func execute(id: UUID, text: String) throws -> PageElement {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DrawingError.emptyText }
        guard var element = try elements.findElement(id: id), element.isText else {
            throw DrawingError.elementNotFound
        }
        element.content = .text(trimmed)
        try elements.save(element)
        return element
    }
}
