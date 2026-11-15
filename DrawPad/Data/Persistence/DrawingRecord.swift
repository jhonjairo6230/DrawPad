import Foundation
import SwiftData

/// Fila de la base de datos: cómo SwiftData guarda un dibujo.
///
/// Es un detalle de la capa Data. El resto de la app usa la entidad
/// ``Drawing``; la conversión se hace en ``SwiftDataDrawingRepository``.
/// Separar "modelo de base de datos" de "entidad de dominio" permite cambiar
/// el esquema sin tocar la lógica.
@Model
final class DrawingRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    /// `.externalStorage`: los datos grandes van a archivos aparte y la base
    /// de datos solo guarda la referencia.
    @Attribute(.externalStorage) var strokesData: Data
    @Attribute(.externalStorage) var thumbnailData: Data?
    var createdAt: Date
    var updatedAt: Date
    /// `CanvasBackground.rawValue`. Es opcional a propósito: las bases de datos
    /// creadas antes de que existieran los fondos no tienen esta columna, y
    /// SwiftData solo sabe añadirla sola si puede dejarla vacía (`nil`).
    var backgroundRaw: String?

    init(id: UUID, title: String, strokesData: Data, thumbnailData: Data?, createdAt: Date, updatedAt: Date, backgroundRaw: String?) {
        self.id = id
        self.title = title
        self.strokesData = strokesData
        self.thumbnailData = thumbnailData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.backgroundRaw = backgroundRaw
    }
}
