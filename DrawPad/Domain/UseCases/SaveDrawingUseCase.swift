import Foundation

/// Guarda los trazos actuales de un dibujo y su miniatura.
struct SaveDrawingUseCase {
    private let repository: DrawingRepository
    /// Reloj inyectable: en las pruebas se fija una fecha conocida.
    private let now: () -> Date

    init(repository: DrawingRepository, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    /// - Throws: ``DrawingError/drawingNotFound`` si el dibujo ya no existe.
    func execute(id: UUID, strokesData: Data, thumbnailData: Data?) throws {
        guard var drawing = try repository.find(id: id) else {
            throw DrawingError.drawingNotFound
        }
        drawing.strokesData = strokesData
        drawing.thumbnailData = thumbnailData
        drawing.updatedAt = now()
        try repository.save(drawing)
    }
}
