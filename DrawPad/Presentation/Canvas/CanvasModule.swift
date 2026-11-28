import Foundation

/// Todo lo que necesita la pantalla de una hoja abierta: su ViewModel y su
/// lienzo, creados juntos para que compartan el mismo `PKCanvasView`.
@MainActor
final class CanvasModule: Identifiable {
    let viewModel: CanvasViewModel
    let canvas: PencilKitCanvas
    /// Monta el editor de un diagrama de Mermaid (texto inicial y tema de la hoja).
    let makeMermaidEditor: (String, CanvasTheme) -> MermaidEditorModule

    init(
        viewModel: CanvasViewModel,
        canvas: PencilKitCanvas,
        makeMermaidEditor: @escaping (String, CanvasTheme) -> MermaidEditorModule
    ) {
        self.viewModel = viewModel
        self.canvas = canvas
        self.makeMermaidEditor = makeMermaidEditor
    }
}

extension CanvasModule: PageSession {
    func flushPendingSave() {
        viewModel.flushPendingSave()
    }

    func discardPendingSave() {
        viewModel.discardPendingSave()
    }
}
