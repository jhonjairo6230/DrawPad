import Foundation

/// Un dibujo del usuario, tal como lo entiende el dominio.
///
/// El dominio no sabe nada de PencilKit: los trazos viajan como datos opacos
/// (`strokesData`). Hoy esos datos son `PKDrawing.dataRepresentation()`, pero
/// si mañana cambiáramos de motor de dibujo, esta entidad no cambiaría.
struct Drawing: Equatable {
    /// Trazos serializados. Solo la capa de presentación sabe interpretarlos.
    let strokesData: Data
    /// Momento del último guardado.
    let updatedAt: Date
}
