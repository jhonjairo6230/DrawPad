import Foundation

/// Añade a una hoja un diagrama de Mermaid ya dibujado.
///
/// Dibujarlo (convertir el texto en imagen) lo hace la presentación, que es
/// quien tiene el motor de Mermaid; el dominio solo valida y guarda, igual que
/// ``ExportDrawingUseCase`` recibe un PNG ya hecho.
struct AddMermaidElementUseCase {
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

    /// - Parameters:
    ///   - imageSize: tamaño del diagrama dibujado, en puntos.
    ///   - maxSize: tamaño máximo al insertarlo; se reduce sin deformarse.
    /// - Throws: ``DrawingError/emptyText`` si no hay texto, o
    ///   ``DrawingError/invalidDiagram(_:)`` si no hay imagen.
    func execute(
        pageID: UUID,
        source: String,
        image: Data,
        imageSize: CGSize,
        centeredAt center: CGPoint,
        maxSize: CGSize
    ) throws -> PageElement {
        let diagram = try MermaidDiagramValidation.validated(source: source, image: image, size: imageSize)
        let element = PageElement(
            id: makeID(),
            pageID: pageID,
            frame: PageElementLayout.frame(
                centeredAt: center,
                size: AddImageElementUseCase.fit(imageSize, within: maxSize)
            ),
            content: .mermaid(diagram),
            createdAt: now()
        )
        try elements.save(element)
        return element
    }
}

/// Comprobaciones comunes a añadir y cambiar un diagrama.
enum MermaidDiagramValidation {
    static func validated(source: String, image: Data, size: CGSize) throws -> MermaidDiagram {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DrawingError.emptyText }
        guard !image.isEmpty, size.width > 0, size.height > 0 else {
            throw DrawingError.invalidDiagram("no se pudo dibujar")
        }
        return MermaidDiagram(source: trimmed, image: image)
    }
}
