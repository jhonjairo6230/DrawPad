import Foundation

/// Cambia el título de un dibujo.
///
/// No toca `updatedAt`: renombrar no cambia el dibujo ni su lugar en la galería.
struct RenameDrawingUseCase {
    private let repository: DrawingRepository

    init(repository: DrawingRepository) {
        self.repository = repository
    }

    /// - Throws: ``DrawingError/invalidTitle`` si el título queda vacío al
    ///   quitar espacios, o ``DrawingError/drawingNotFound``.
    func execute(id: UUID, title: String) throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DrawingError.invalidTitle }
        guard var drawing = try repository.find(id: id) else {
            throw DrawingError.drawingNotFound
        }
        drawing.title = trimmed
        try repository.save(drawing)
    }
}
