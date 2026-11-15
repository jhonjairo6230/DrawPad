import Foundation

/// Cambia el papel de una hoja: su patrón y si es claro u oscuro.
///
/// No toca `updatedAt`: los trazos no cambian.
struct ChangeBackgroundUseCase {
    private let repository: DrawingRepository

    init(repository: DrawingRepository) {
        self.repository = repository
    }

    /// - Throws: ``DrawingError/drawingNotFound`` si la hoja ya no existe.
    func execute(id: UUID, background: CanvasBackground, theme: CanvasTheme) throws {
        guard var drawing = try repository.findDrawing(id: id) else {
            throw DrawingError.drawingNotFound
        }
        drawing.background = background
        drawing.theme = theme
        try repository.save(drawing)
    }
}
