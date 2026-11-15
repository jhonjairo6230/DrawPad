import Foundation

/// Recupera una hoja completa para abrirla en el lienzo.
struct LoadDrawingUseCase {
    private let repository: DrawingRepository

    init(repository: DrawingRepository) {
        self.repository = repository
    }

    /// - Throws: ``DrawingError/drawingNotFound`` si la hoja no existe.
    func execute(id: UUID) throws -> Drawing {
        guard let drawing = try repository.findDrawing(id: id) else {
            throw DrawingError.drawingNotFound
        }
        return drawing
    }
}
