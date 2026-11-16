import Foundation

/// Petición de abrir el editor de texto: para un cuadro nuevo (`elementID`
/// es `nil`) o para cambiar uno que ya está en la hoja.
///
/// Es `Identifiable` para presentarlo con `.sheet(item:)`.
struct TextEditorRequest: Identifiable, Equatable {
    let id = UUID()
    let elementID: UUID?
    let text: String

    var isNew: Bool { elementID == nil }
}
