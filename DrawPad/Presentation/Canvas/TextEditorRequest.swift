import Foundation

/// Petición de abrir el editor de texto: para un cuadro nuevo (`elementID`
/// es `nil`), para cambiar uno que ya está en la hoja o para el texto de una
/// figura.
///
/// Es `Identifiable` para presentarlo con `.sheet(item:)`.
struct TextEditorRequest: Identifiable, Equatable {
    let id = UUID()
    let elementID: UUID?
    let text: String
    /// `true` si es el texto de una figura, que puede quedar vacío.
    var isShapeLabel = false

    var isNew: Bool { elementID == nil }
}
