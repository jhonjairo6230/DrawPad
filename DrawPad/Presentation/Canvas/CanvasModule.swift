import Foundation

/// Todo lo que necesita la pantalla de una hoja abierta: su ViewModel y su
/// lienzo, creados juntos para que compartan el mismo `PKCanvasView`.
@MainActor
final class CanvasModule: Identifiable {
    let viewModel: CanvasViewModel
    let canvas: PencilKitCanvas

    init(viewModel: CanvasViewModel, canvas: PencilKitCanvas) {
        self.viewModel = viewModel
        self.canvas = canvas
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
