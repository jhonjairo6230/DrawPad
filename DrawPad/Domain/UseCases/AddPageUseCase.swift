import Foundation

/// Añade una hoja en blanco al final de un cuaderno.
///
/// La hoja nueva hereda el papel de la última (patrón y tema), como en un
/// cuaderno de verdad: si vienes escribiendo en cuadrícula, la siguiente hoja
/// también es de cuadrícula.
struct AddPageUseCase {
    private let drawings: DrawingRepository
    private let now: () -> Date
    private let makeID: () -> UUID

    init(
        drawings: DrawingRepository,
        now: @escaping () -> Date = Date.init,
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.drawings = drawings
        self.now = now
        self.makeID = makeID
    }

    func execute(notebookID: UUID) throws -> Drawing {
        let lastPage = try drawings.listDrawings(notebookID: notebookID).last
            .flatMap { try drawings.findDrawing(id: $0.id) }
        let date = now()
        let page = Drawing(
            id: makeID(),
            notebookID: notebookID,
            strokesData: Data(),
            thumbnailData: nil,
            createdAt: date,
            updatedAt: date,
            background: lastPage?.background ?? .blank,
            theme: lastPage?.theme ?? .light
        )
        try drawings.save(page)
        return page
    }
}
