import Foundation

/// Los casos de uso de textos e imágenes que necesita ``CanvasViewModel``,
/// agrupados para no alargar su `init` con seis parámetros más.
struct PageElementUseCases {
    let list: ListPageElementsUseCase
    let addText: AddTextElementUseCase
    let paste: PasteElementUseCase
    let updateText: UpdateElementTextUseCase
    let move: MoveElementUseCase
    let delete: DeleteElementUseCase

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
    }
}
