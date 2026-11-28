import Foundation

/// Añade un cuadro de texto a una hoja.
struct AddTextElementUseCase {
    private let elements: PageElementRepository
    private let now: () -> Date
    private let makeID: () -> UUID

    init(
        elements: PageElementRepository,
        now: @escaping () -> Date = Date.init,
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.elements = elements
        self.now = now
        self.makeID = makeID
    }

    /// - Parameter center: dónde colocarlo, en coordenadas de la hoja
    ///   (normalmente, el centro de lo que se está viendo).
    /// - Throws: ``DrawingError/emptyText`` si el texto queda vacío al quitar
    ///   espacios.
    func execute(pageID: UUID, text: String, centeredAt center: CGPoint) throws -> PageElement {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DrawingError.emptyText }
        let element = PageElement(
            id: makeID(),
            pageID: pageID,
            frame: PageElementLayout.frame(
                centeredAt: center,
                size: CGSize(width: PageElementLayout.textWidth, height: PageElementLayout.textLineHeight)
            ),
            content: .text(trimmed),
            createdAt: now()
        )
        try elements.save(element)
        return element
    }
}
