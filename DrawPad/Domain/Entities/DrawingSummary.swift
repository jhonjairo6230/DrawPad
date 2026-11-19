import Foundation

/// Lo justo de una hoja para listarla dentro de su cuaderno.
///
/// No incluye los trazos: así listar las hojas no las carga enteras en memoria.
struct DrawingSummary: Equatable, Identifiable {
    let id: UUID
    let thumbnailData: Data?
    let updatedAt: Date
    /// Para saber qué pantalla abrir sin cargar la hoja entera.
    var kind: PageKind = .drawing
}

extension Drawing {
    var summary: DrawingSummary {
        DrawingSummary(id: id, thumbnailData: thumbnailData, updatedAt: updatedAt, kind: kind)
    }
}
