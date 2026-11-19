import Foundation

/// El editor de un diagrama: su ViewModel y la vista web que dibuja, creados
/// juntos por ``AppContainer``.
@MainActor
final class MermaidEditorModule {
    let viewModel: MermaidEditorViewModel
    let preview: WebKitMermaidPreview

    init(viewModel: MermaidEditorViewModel, preview: WebKitMermaidPreview) {
        self.viewModel = viewModel
        self.preview = preview
    }
}

/// Petición de abrir el editor: para un diagrama nuevo (`elementID` es
/// `nil`) o para cambiar uno de la hoja. Es `Identifiable` para presentarlo
/// con `.sheet(item:)`.
struct MermaidEditorRequest: Identifiable, Equatable {
    let id = UUID()
    let elementID: UUID?
    let source: String

    var isNew: Bool { elementID == nil }

    /// Ejemplo con el que empieza un diagrama nuevo.
    static let template = """
    flowchart LR
        App[App del iPad] --> API[API]
        API --> DB[(Base de datos)]
        API --> Cola[[Cola de mensajes]]
    """
}
