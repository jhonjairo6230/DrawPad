import SwiftUI

/// Qué se puede cambiar en este dispositivo.
///
/// En el iPad, todo. En el iPhone no hay Apple Pencil ni espacio para las
/// herramientas de dibujo, pero sí teclado y dedo: se **escribe Markdown** y
/// se hacen **diagramas** (figuras, conexiones y Mermaid); los trazos solo se
/// leen (ver docs/adr/0018, 0021 y 0022). Lo decide ``AppContainer`` y lo reparte por el
/// entorno de SwiftUI, para que cada pantalla esconda lo que no aplica.
struct EditingCapabilities: Equatable {
    /// Crear, renombrar, cambiar la portada y eliminar cuadernos.
    var canManageNotebooks: Bool
    /// Dibujar trazos y el resto de herramientas del lienzo: deshacer, papel,
    /// dibujar con el dedo, suavizar, borrar todo, cuadros de texto, pegar.
    /// También borrar hojas de dibujo.
    var canDraw: Bool
    /// Figuras, conexiones y diagramas Mermaid en las hojas de dibujo
    /// (insertar, mover, conectar, girar, editar y eliminar), y añadir hojas
    /// de dibujo para ellos.
    var canEditDiagrams: Bool
    /// Crear, editar, importar y borrar hojas Markdown.
    var canWriteMarkdown: Bool

    /// iPad: se puede todo.
    static let full = EditingCapabilities(
        canManageNotebooks: true, canDraw: true, canEditDiagrams: true, canWriteMarkdown: true
    )

    /// iPhone: Markdown y diagramas; sin trazos.
    static let phone = EditingCapabilities(
        canManageNotebooks: false, canDraw: false, canEditDiagrams: true, canWriteMarkdown: true
    )

    /// ¿Se pueden añadir hojas de dibujo (para trazos o para diagramas)?
    var canAddDrawingPages: Bool { canDraw || canEditDiagrams }

    /// ¿Hay algo que hacer en una hoja de dibujo, además de leerla?
    var canEditDrawingPages: Bool { canDraw || canEditDiagrams }

    /// ¿Se puede añadir alguna clase de hoja?
    var canAddPages: Bool { canAddDrawingPages || canWriteMarkdown }

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
