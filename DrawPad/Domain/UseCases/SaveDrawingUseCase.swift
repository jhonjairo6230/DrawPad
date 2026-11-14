import Foundation

/// Guarda el estado actual del lienzo.
struct SaveDrawingUseCase {
    private let repository: DrawingRepository
    /// Reloj inyectable: en las pruebas se fija una fecha conocida.
    private let now: () -> Date

    init(repository: DrawingRepository, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    func execute(strokesData: Data) throws {
        try repository.save(Drawing(strokesData: strokesData, updatedAt: now()))
    }
}
