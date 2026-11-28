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
    /// `CoverColor.rawValue`. Opcional: los cuadernos creados antes de las
    /// tapas no tienen esta columna (ver ``DrawingRecord``).
    var coverColorRaw: String?
    /// `CoverStyle.rawValue`. Opcional por el mismo motivo.
    var coverStyleRaw: String?
    /// Trazos del dibujo de la tapa. Solo hay dibujo si esta columna y la
    /// siguiente tienen valor.
    @Attribute(.externalStorage) var coverStrokesData: Data?
    /// Imagen PNG del dibujo de la tapa.
    @Attribute(.externalStorage) var coverImageData: Data?

    init(id: UUID, title: String, createdAt: Date, coverColorRaw: String?, coverStyleRaw: String?) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.coverColorRaw = coverColorRaw
        self.coverStyleRaw = coverStyleRaw
    }
}
