import Foundation

/// Recupera el dibujo con el que el usuario estaba trabajando.
struct LoadDrawingUseCase {
    private let repository: DrawingRepository

    init(repository: DrawingRepository) {
        self.repository = repository
    }

    /// - Returns: el último dibujo guardado, o `nil` si es la primera vez.
    func execute() throws -> Drawing? {
        try repository.load()
    }
}
