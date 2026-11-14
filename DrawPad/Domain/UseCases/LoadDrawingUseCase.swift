import Foundation

/// Recupera un dibujo completo para abrirlo en el lienzo.
struct LoadDrawingUseCase {
    private let repository: DrawingRepository

    init(repository: DrawingRepository) {
        self.repository = repository
    }

    /// - Throws: ``DrawingError/drawingNotFound`` si el dibujo no existe.
    func execute(id: UUID) throws -> Drawing {
        guard let drawing = try repository.find(id: id) else {
            throw DrawingError.drawingNotFound
        }
        return drawing
    }
}
