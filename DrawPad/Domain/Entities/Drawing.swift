import Foundation

/// Un dibujo del usuario, tal como lo entiende el dominio.
///
/// El dominio no sabe nada de PencilKit: los trazos viajan como datos opacos
/// (`strokesData`). Hoy esos datos son `PKDrawing.dataRepresentation()`, pero
/// si mañana cambiáramos de motor de dibujo, esta entidad no cambiaría.
struct Drawing: Equatable, Identifiable {
    let id: UUID
    var title: String
    /// Trazos serializados. Solo la capa de presentación sabe interpretarlos.
    /// Vacío en un dibujo recién creado.
    var strokesData: Data
    /// Miniatura PNG para la galería; `nil` si el dibujo está vacío.
    var thumbnailData: Data?
    let createdAt: Date
    /// Momento del último cambio en los trazos.
    var updatedAt: Date
    /// Papel de fondo. No forma parte de los trazos: se puede cambiar sin tocarlos.
    var background: CanvasBackground = .blank
    /// Papel claro u oscuro.
    var theme: CanvasTheme = .light
}
