import Foundation
import SwiftData

/// Fila de la base de datos: un texto o una imagen colocados en una hoja.
///
/// Los dos tipos comparten tabla: `kindRaw` dice cuál es, y solo una de las
/// columnas `text` / `imageData` tiene valor. Apunta a su hoja con `pageID`
/// (clave ajena explícita, como ``DrawingRecord/notebookID``).
@Model
final class PageElementRecord {
    static let textKind = "text"
    static let imageKind = "image"

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
