import Foundation

/// Lo justo de un dibujo para mostrarlo en la galería.
///
/// No incluye los trazos: así listar cien dibujos no carga cien dibujos
/// completos en memoria.
struct DrawingSummary: Equatable, Identifiable {
    let id: UUID
    let title: String
    let thumbnailData: Data?
    let updatedAt: Date
}

extension Drawing {
    var summary: DrawingSummary {
        DrawingSummary(id: id, title: title, thumbnailData: thumbnailData, updatedAt: updatedAt)
    }
}
