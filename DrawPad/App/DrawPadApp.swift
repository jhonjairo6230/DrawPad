import SwiftUI

/// Punto de entrada de la app.
///
/// Crea el ``AppContainer`` una sola vez y entrega a la pantalla sus
/// dependencias ya construidas.
@main
struct DrawPadApp: App {
    @State private var viewModel: CanvasViewModel
    private let canvas: PencilKitCanvas

    init() {
        let container = AppContainer()
        canvas = container.canvas
        _viewModel = State(initialValue: container.makeCanvasViewModel())
    }

    var body: some Scene {
        WindowGroup {
            CanvasScreen(viewModel: viewModel, canvas: canvas)
                .preferredColorScheme(.light)
        }
    }
}
