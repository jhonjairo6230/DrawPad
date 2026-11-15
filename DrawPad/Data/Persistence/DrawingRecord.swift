import Foundation
import SwiftData

/// Fila de la base de datos: cómo SwiftData guarda una hoja.
///
/// Es un detalle de la capa Data. El resto de la app usa la entidad
/// ``Drawing``; la conversión se hace en ``SwiftDataLibrary``.
/// Separar "modelo de base de datos" de "entidad de dominio" permite cambiar
/// el esquema sin tocar la lógica.
///
/// Las propiedades añadidas después de la primera versión son **opcionales a
/// propósito**: las bases de datos ya instaladas no tienen esas columnas, y
/// SwiftData solo sabe añadirlas sola si puede dejarlas vacías (`nil`).
@Model
final class DrawingRecord {
    @Attribute(.unique) var id: UUID
    /// Título de cuando cada dibujo era independiente (antes de los
    /// cuadernos). Hoy solo lo lee ``SwiftDataLibrary/adoptOrphanDrawings()``
    /// para ponérselo al cuaderno que se crea a partir del dibujo.
    var title: String
    /// `.externalStorage`: los datos grandes van a archivos aparte y la base
    /// de datos solo guarda la referencia.
    @Attribute(.externalStorage) var strokesData: Data
    @Attribute(.externalStorage) var thumbnailData: Data?
    var createdAt: Date
    var updatedAt: Date
    /// `CanvasBackground.rawValue`.
    var backgroundRaw: String?
    /// `CanvasTheme.rawValue`.
    var themeRaw: String?
    /// Cuaderno al que pertenece. `nil` solo en dibujos anteriores a los
    /// cuadernos, hasta que se les crea uno al arrancar.
    var notebookID: UUID?

    init(
        id: UUID,
        title: String = "",
        strokesData: Data,
        thumbnailData: Data?,
        createdAt: Date,
        updatedAt: Date,
        backgroundRaw: String?,
        themeRaw: String?,
        notebookID: UUID?
    ) {
        self.id = id
        self.title = title
        self.strokesData = strokesData
        self.thumbnailData = thumbnailData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.backgroundRaw = backgroundRaw
        self.themeRaw = themeRaw
        self.notebookID = notebookID
    }
}
