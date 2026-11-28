import Foundation

/// Un cuaderno: una carpeta con título que agrupa hojas (``Drawing``).
struct Notebook: Equatable, Identifiable {
    let id: UUID
    var title: String
    let createdAt: Date
    var cover: NotebookCover = .standard
}
