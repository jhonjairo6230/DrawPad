import Foundation

/// Cambia el papel de un dibujo: su patrón y si es claro u oscuro.
///
/// Como renombrar, no toca `updatedAt`: los trazos no cambian.
struct ChangeBackgroundUseCase {
    private let repository: DrawingRepository

    init(repository: DrawingRepository) {
        self.repository = repository
    }

    /// - Throws: ``DrawingError/drawingNotFound`` si el dibujo ya no existe.
    func execute(id: UUID, background: CanvasBackground, theme: CanvasTheme) throws {
        guard var drawing = try repository.find(id: id) else {
            throw DrawingError.drawingNotFound
        }
        drawing.background = background
        drawing.theme = theme
        try repository.save(drawing)
    }
}
