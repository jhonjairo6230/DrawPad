import Foundation

/// Una hoja de un cuaderno, tal como la entiende el dominio.
///
/// El dominio no sabe nada de PencilKit: los trazos viajan como datos opacos
/// (`strokesData`). Hoy esos datos son `PKDrawing.dataRepresentation()`, pero
/// si mañana cambiáramos de motor de dibujo, esta entidad no cambiaría.
struct Drawing: Equatable, Identifiable {
    let id: UUID
    /// Cuaderno al que pertenece la hoja.
    let notebookID: UUID
    /// Trazos serializados. Solo la capa de presentación sabe interpretarlos.
    /// Vacío en una hoja recién creada.
    var strokesData: Data
    /// Miniatura PNG para la galería; `nil` si la hoja está vacía.
    var thumbnailData: Data?
    /// Las hojas se ordenan por fecha de creación: la más antigua es la primera.
    let createdAt: Date
    /// Momento del último cambio en los trazos.
    var updatedAt: Date
    /// Papel de fondo. No forma parte de los trazos: se puede cambiar sin tocarlos.
    var background: CanvasBackground = .blank
    /// Papel claro u oscuro.
    var theme: CanvasTheme = .light
}
