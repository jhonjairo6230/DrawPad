import Foundation

/// Lista los textos e imágenes de una hoja, del fondo hacia arriba.
struct ListPageElementsUseCase {
    private let elements: PageElementRepository

    init(elements: PageElementRepository) {
        self.elements = elements
    }

    func execute(pageID: UUID) throws -> [PageElement] {
        try elements.listElements(pageID: pageID)
    }
}
