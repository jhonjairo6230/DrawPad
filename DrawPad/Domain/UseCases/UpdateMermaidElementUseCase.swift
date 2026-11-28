import Foundation

/// Cambia el texto de un diagrama de Mermaid ya colocado, con su nueva imagen.
///
/// El diagrama conserva su centro; el tamaño se recalcula a partir de la
/// imagen nueva (un diagrama con más cajas ocupa más), sin pasar de `maxSize`.
struct UpdateMermaidElementUseCase {
    private let elements: PageElementRepository

    init(elements: PageElementRepository) {
        self.elements = elements
    }

    /// - Throws: ``DrawingError/elementNotFound`` si no existe o no es un
    ///   diagrama, o los errores de ``MermaidDiagramValidation``.
    func execute(id: UUID, source: String, image: Data, imageSize: CGSize, maxSize: CGSize) throws -> PageElement {
        let diagram = try MermaidDiagramValidation.validated(source: source, image: image, size: imageSize)
        guard var element = try elements.findElement(id: id), element.isMermaid else {
            throw DrawingError.elementNotFound
        }
        let center = CGPoint(x: element.frame.midX, y: element.frame.midY)
        element.content = .mermaid(diagram)
        element.frame = MoveElementUseCase.corrected(PageElementLayout.frame(
            centeredAt: center,
            size: AddImageElementUseCase.fit(imageSize, within: maxSize)
        ))
        try elements.save(element)
        return element
    }
}
