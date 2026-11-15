import Foundation

/// Cambia el papel de fondo de un dibujo.
///
/// Como renombrar, no toca `updatedAt`: los trazos no cambian.
struct ChangeBackgroundUseCase {
    private let repository: DrawingRepository

    init(repository: DrawingRepository) {
        self.repository = repository
    }

    /// - Throws: ``DrawingError/drawingNotFound`` si el dibujo ya no existe.
    func execute(id: UUID, background: CanvasBackground) throws {
        guard var drawing = try repository.find(id: id) else {
            throw DrawingError.drawingNotFound
        }
        drawing.background = background
        try repository.save(drawing)
    }
}
