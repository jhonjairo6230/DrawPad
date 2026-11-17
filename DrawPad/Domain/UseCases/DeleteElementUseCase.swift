import Foundation

/// Quita un texto o una imagen de la hoja.
struct DeleteElementUseCase {
    private let elements: PageElementRepository

    init(elements: PageElementRepository) {
        self.elements = elements
    }

    func execute(id: UUID) throws {
        try elements.deleteElement(id: id)
    }
}
