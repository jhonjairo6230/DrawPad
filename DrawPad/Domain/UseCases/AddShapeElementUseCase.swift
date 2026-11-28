import Foundation

/// Añade una figura de diagrama a una hoja, de pie y sin texto.
struct AddShapeElementUseCase {
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

    /// - Parameter center: dónde colocarla, en coordenadas de la hoja.
    func execute(pageID: UUID, kind: ShapeKind, centeredAt center: CGPoint) throws -> PageElement {
        let element = PageElement(
            id: makeID(),
            pageID: pageID,
            frame: PageElementLayout.frame(centeredAt: center, size: kind.defaultSize),
            content: .shape(DiagramShape(kind: kind)),
            createdAt: now()
        )
        try elements.save(element)
        return element
    }
}
