import Foundation
import SwiftData

/// Fila de la base de datos: cómo SwiftData guarda un cuaderno.
///
/// Sus hojas no se guardan aquí: cada ``DrawingRecord`` apunta a su cuaderno
/// con `notebookID`. Es una clave ajena explícita, en lugar de una relación
/// de SwiftData, para que el mapeo a las entidades de dominio sea directo.
@Model
final class NotebookRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date

    init(id: UUID, title: String, createdAt: Date) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
    }
}
