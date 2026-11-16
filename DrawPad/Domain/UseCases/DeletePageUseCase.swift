import Foundation

/// Elimina una hoja de su cuaderno.
///
/// Regla de negocio: un cuaderno nunca se queda sin hojas. Para deshacerse de
/// la última, se elimina el cuaderno.
struct DeletePageUseCase {
    private let drawings: DrawingRepository

    init(drawings: DrawingRepository) {
        self.drawings = drawings
    }

    /// - Throws: ``DrawingError/lastPage`` si es la única hoja del cuaderno, o
    ///   ``DrawingError/drawingNotFound`` si ya no existe.
    func execute(id: UUID) throws {
        guard let page = try drawings.findDrawing(id: id) else {
            throw DrawingError.drawingNotFound
        }
        guard try drawings.listDrawings(notebookID: page.notebookID).count > 1 else {
            throw DrawingError.lastPage
        }
        try drawings.deleteDrawing(id: id)
    }
}
