import SwiftUI

/// Punto de entrada de la app.
///
/// Guarda el ``AppContainer`` (que al crearse no construye nada) y, cuando la
/// escena se muestra, le pide a la pantalla sus dependencias.
@main
struct DrawPadApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            CanvasScreen(viewModel: container.canvasViewModel, canvas: container.canvas)
                .preferredColorScheme(.light)
        }
    }
}
