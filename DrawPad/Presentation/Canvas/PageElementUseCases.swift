import Foundation

/// Los casos de uso de textos, imágenes, figuras y conexiones que necesita
/// ``CanvasViewModel``, agrupados para no alargar su `init`.
struct PageElementUseCases {
    let list: ListPageElementsUseCase
    let addText: AddTextElementUseCase
    let paste: PasteElementUseCase
    let updateText: UpdateElementTextUseCase
    let move: MoveElementUseCase
    let delete: DeleteElementUseCase
    let addShape: AddShapeElementUseCase
    let rotate: RotateShapeUseCase
    let connect: ConnectElementsUseCase
    let addMermaid: AddMermaidElementUseCase
    let updateMermaid: UpdateMermaidElementUseCase

    /// Todos sobre el mismo repositorio y el mismo portapapeles.
    init(elements: PageElementRepository, clipboard: Clipboard) {
        let addText = AddTextElementUseCase(elements: elements)
        self.list = ListPageElementsUseCase(elements: elements)
        self.addText = addText
        self.paste = PasteElementUseCase(
            clipboard: clipboard,
            addText: addText,
            addImage: AddImageElementUseCase(elements: elements)
        )
        self.updateText = UpdateElementTextUseCase(elements: elements)
        self.move = MoveElementUseCase(elements: elements)
        self.delete = DeleteElementUseCase(elements: elements)
        self.addShape = AddShapeElementUseCase(elements: elements)
        self.rotate = RotateShapeUseCase(elements: elements)
        self.connect = ConnectElementsUseCase(elements: elements)
        self.addMermaid = AddMermaidElementUseCase(elements: elements)
        self.updateMermaid = UpdateMermaidElementUseCase(elements: elements)
    }
}
