import Foundation

/// La pantalla de dibujar la portada: su ViewModel y su lienzo, creados
/// juntos por ``AppContainer``. Es `Identifiable` para presentarla con
/// `.fullScreenCover(item:)`.
@MainActor
final class CoverDrawingModule: Identifiable {
    let viewModel: CoverDrawingViewModel
    let canvas: PencilKitCanvas

    init(viewModel: CoverDrawingViewModel, canvas: PencilKitCanvas) {
        self.viewModel = viewModel
        self.canvas = canvas
    }
}
