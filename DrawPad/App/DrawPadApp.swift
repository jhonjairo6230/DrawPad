import SwiftUI

/// Punto de entrada de la app.
///
/// Guarda el ``AppContainer`` (que al crearse no construye nada) y, cuando la
/// escena se muestra, le pide la galería y la fábrica de pantallas de dibujo.
@main
struct DrawPadApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            GalleryScreen(
                viewModel: container.galleryViewModel,
                makeCanvas: container.makeCanvasModule(drawingID:)
            )
        }
    }
}
