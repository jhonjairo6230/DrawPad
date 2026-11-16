import Foundation

/// Lo justo de un cuaderno para mostrarlo en la galería.
struct NotebookSummary: Equatable, Identifiable {
    let id: UUID
    let title: String
    let pageCount: Int
    /// Miniatura de la primera hoja; `nil` si está vacía.
    let coverThumbnailData: Data?
    /// Última vez que se tocó el cuaderno: su creación o el último cambio en
    /// cualquiera de sus hojas.
    let lastActivityAt: Date
}
