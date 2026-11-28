import Foundation

/// Pega en una hoja lo que haya en el portapapeles: una imagen o un texto.
struct PasteElementUseCase {
    private let clipboard: Clipboard
    private let addText: AddTextElementUseCase
    private let addImage: AddImageElementUseCase

    init(clipboard: Clipboard, addText: AddTextElementUseCase, addImage: AddImageElementUseCase) {
        self.clipboard = clipboard
        self.addText = addText
        self.addImage = addImage
    }

    /// - Throws: ``DrawingError/clipboardEmpty`` si no hay nada que pegar.
    func execute(pageID: UUID, centeredAt center: CGPoint, maxImageSize: CGSize) throws -> PageElement {
        switch clipboard.content() {
        case .text(let text):
            do {
                return try addText.execute(pageID: pageID, text: text, centeredAt: center)
            } catch DrawingError.emptyText {
                // Un portapapeles con solo espacios es, para el usuario, uno vacío.
                throw DrawingError.clipboardEmpty
            }
        case .image(let data, let size):
            return try addImage.execute(
                pageID: pageID, imageData: data, imageSize: size, centeredAt: center, maxSize: maxImageSize
            )
        case nil:
            throw DrawingError.clipboardEmpty
        }
    }
}
