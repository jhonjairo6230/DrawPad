import Foundation

/// Elimina un dibujo de forma definitiva.
struct DeleteDrawingUseCase {
    private let repository: DrawingRepository

    init(repository: DrawingRepository) {
        self.repository = repository
    }

    func execute(id: UUID) throws {
        try repository.delete(id: id)
    }
}
