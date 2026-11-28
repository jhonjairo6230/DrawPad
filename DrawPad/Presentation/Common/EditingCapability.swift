import SwiftUI

/// Qué se puede cambiar en este dispositivo.
///
/// En el iPad, todo. En el iPhone no hay Apple Pencil ni espacio para las
/// herramientas de dibujo, pero sí teclado y dedo: se **escribe Markdown** y
/// se hacen **diagramas** (figuras, conexiones y Mermaid), y se crean y
/// arreglan cuadernos; los trazos solo se leen (ver docs/adr/0018, 0021, 0022
/// y 0024). Lo decide ``AppContainer`` y lo reparte por el entorno de
/// SwiftUI, para que cada pantalla esconda lo que no aplica.
struct EditingCapabilities: Equatable {
    /// Crear, renombrar y cambiar la portada de cuadernos (la portada
    /// dibujada, además, pide `canDraw`).
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

    /// iPhone: cuadernos, Markdown y diagramas; sin trazos.
    static let phone = EditingCapabilities(
        canManageNotebooks: true, canDraw: false, canEditDiagrams: true, canWriteMarkdown: true
    )

    /// ¿Se pueden añadir hojas de dibujo (para trazos o para diagramas)?
    var canAddDrawingPages: Bool { canDraw || canEditDiagrams }

    /// ¿Hay algo que hacer en una hoja de dibujo, además de leerla?
    var canEditDrawingPages: Bool { canDraw || canEditDiagrams }

    /// Estilos de portada que se ofrecen. "Dibujo" se dibuja con el Pencil:
    /// sin `canDraw` no se ofrece, salvo que la portada ya lo tenga (para no
    /// quitárselo al guardar otro cambio).
    func coverStyles(current: CoverStyle) -> [CoverStyle] {
        CoverStyle.allCases.filter { $0 != .drawn || canDraw || current == .drawn }
    }

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
