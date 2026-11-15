import Foundation
@testable import DrawPad

/// Repositorio falso: guarda los dibujos en memoria y puede simular fallos.
final class InMemoryDrawingRepository: DrawingRepository {
    private(set) var drawings: [UUID: Drawing] = [:]
    var error: DrawingError?
    private(set) var saveCount = 0

    init(_ drawings: [Drawing] = []) {
        for drawing in drawings {
            self.drawings[drawing.id] = drawing
        }
    }

    func list() throws -> [DrawingSummary] {
        if let error { throw error }
        return drawings.values
            .sorted { $0.updatedAt > $1.updatedAt }
            .map(\.summary)
    }

    func find(id: UUID) throws -> Drawing? {
        if let error { throw error }
        return drawings[id]
    }

    func save(_ drawing: Drawing) throws {
        if let error { throw error }
        drawings[drawing.id] = drawing
        saveCount += 1
    }

    func delete(id: UUID) throws {
        if let error { throw error }
        drawings[id] = nil
    }
}

extension Drawing {
    /// Dibujo de ejemplo para las pruebas; cada una cambia solo lo que le importa.
    static func sample(
        id: UUID = UUID(),
        title: String = "Dibujo",
        strokes: String = "",
        thumbnail: String? = nil,
        updatedAt: Date = Date(timeIntervalSince1970: 100)
    ) -> Drawing {
        Drawing(
            id: id,
            title: title,
            strokesData: Data(strokes.utf8),
            thumbnailData: thumbnail.map { Data($0.utf8) },
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: updatedAt
        )
    }
}
