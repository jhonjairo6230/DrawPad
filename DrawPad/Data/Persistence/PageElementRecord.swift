import Foundation
import SwiftData

/// Fila de la base de datos: un elemento colocado en una hoja (texto, imagen,
/// figura o conexión).
///
/// Todos los tipos comparten tabla: `kindRaw` dice cuál es y solo tienen
/// valor las columnas que ese tipo usa. Una figura guarda su texto en `text`.
/// Las columnas añadidas para figuras y conexiones son opcionales, para que
/// SwiftData migre sola la base de datos ya instalada. Apunta a su hoja con `pageID`
/// (clave ajena explícita, como ``DrawingRecord/notebookID``).
@Model
final class PageElementRecord {
    static let textKind = "text"
    static let imageKind = "image"
    static let shapeKind = "shape"
    static let connectorKind = "connector"

    @Attribute(.unique) var id: UUID
    var pageID: UUID
    var kindRaw: String
    var text: String?
    @Attribute(.externalStorage) var imageData: Data?
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var createdAt: Date
    /// `ShapeKind.rawValue` (solo figuras).
    var shapeKindRaw: String?
    /// Giro en cuartos de vuelta (solo figuras).
    var quarterTurns: Int?
    /// Extremos de una conexión.
    var fromID: UUID?
    var toID: UUID?
    /// `ConnectorStyle.rawValue` (solo conexiones).
    var connectorStyleRaw: String?

    init(
        id: UUID,
        pageID: UUID,
        kindRaw: String,
        text: String?,
        imageData: Data?,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        createdAt: Date
    ) {
        self.id = id
        self.pageID = pageID
        self.kindRaw = kindRaw
        self.text = text
        self.imageData = imageData
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.createdAt = createdAt
    }
}
