import SwiftUI

/// Qué se puede cambiar en este dispositivo.
///
/// En el iPad, todo. En el iPhone no hay Apple Pencil ni espacio para las
/// herramientas de dibujo, pero sí teclado: se **escribe Markdown** (crear,
/// editar, importar y borrar hojas Markdown) y el resto **solo se lee** (ver
/// docs/adr/0018 y 0021). Lo decide ``AppContainer`` y lo reparte por el
/// entorno de SwiftUI, para que cada pantalla esconda lo que no aplica.
struct EditingCapabilities: Equatable {
    /// Crear, renombrar, cambiar la portada y eliminar cuadernos.
    var canManageNotebooks: Bool
    /// Dibujar y todo lo de las hojas de dibujo: añadirlas, borrarlas,
    /// herramientas, papel, textos, imágenes y figuras.
    var canDraw: Bool
    /// Crear, editar, importar y borrar hojas Markdown.
    var canWriteMarkdown: Bool

    /// iPad: se puede todo.
    static let full = EditingCapabilities(canManageNotebooks: true, canDraw: true, canWriteMarkdown: true)

    /// iPhone: solo texto.
    static let phone = EditingCapabilities(canManageNotebooks: false, canDraw: false, canWriteMarkdown: true)

    /// ¿Se puede añadir alguna clase de hoja?
    var canAddPages: Bool { canDraw || canWriteMarkdown }

    /// ¿Se puede borrar una hoja de este tipo?
    func canDeletePage(of kind: PageKind) -> Bool {
        switch kind {
        case .drawing: canDraw
        case .markdown: canWriteMarkdown
        }
    }
}

private struct EditingCapabilitiesKey: EnvironmentKey {
    static let defaultValue = EditingCapabilities.full
}

extension EnvironmentValues {
    var editing: EditingCapabilities {
        get { self[EditingCapabilitiesKey.self] }
        set { self[EditingCapabilitiesKey.self] = newValue }
    }
}
