import Foundation
@testable import DrawPad

/// Repositorio falso: guarda el dibujo en memoria y puede simular fallos.
final class InMemoryDrawingRepository: DrawingRepository {
    var stored: Drawing?
    var error: DrawingError?
    private(set) var saveCount = 0

    init(stored: Drawing? = nil) {
        self.stored = stored
    }

    func load() throws -> Drawing? {
        if let error { throw error }
        return stored
    }

    func save(_ drawing: Drawing) throws {
        if let error { throw error }
        stored = drawing
        saveCount += 1
    }
}
