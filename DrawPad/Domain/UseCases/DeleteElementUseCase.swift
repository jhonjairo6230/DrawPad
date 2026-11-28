import Foundation

/// Quita un elemento de la hoja.
///
/// Regla: al quitar una figura (o un texto, o una imagen), también se quitan
/// las flechas y líneas que llegaban o salían de él. Una conexión con un
/// extremo suelto no tendría dónde dibujarse.
struct DeleteElementUseCase {
    private let elements: PageElementRepository

    init(elements: PageElementRepository) {
        self.elements = elements
    }

    func execute(id: UUID) throws {
        guard let element = try elements.findElement(id: id) else { return }
        if !element.isConnector {
            for connector in try elements.listElements(pageID: element.pageID) where connector.connects(id) {
                try elements.deleteElement(id: connector.id)
            }
        }
        try elements.deleteElement(id: id)
    }
}
