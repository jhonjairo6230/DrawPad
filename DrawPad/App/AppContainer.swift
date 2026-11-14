import Foundation

/// *Composition root*: el único lugar donde se crean las implementaciones
/// concretas y se conectan entre sí (inyección de dependencias manual).
///
/// El resto del código solo conoce protocolos. Para cambiar, por ejemplo, el
/// almacenamiento a iCloud, bastaría con cambiar una línea aquí.
///
/// **Todo es `lazy` a propósito.** `DrawPadApp.init()` se ejecuta antes de que
/// exista `UIApplication`; un `PKCanvasView` creado tan pronto deja sus gestos
/// mal inicializados y la app se cierra al primer toque con el dedo. Al ser
/// `lazy`, el lienzo se crea cuando la escena pide la pantalla por primera vez.
@MainActor
final class AppContainer {
    private(set) lazy var canvas = PencilKitCanvas()

    private(set) lazy var canvasViewModel = CanvasViewModel(
        canvas: canvas,
        loadDrawing: LoadDrawingUseCase(repository: drawingRepository),
        saveDrawing: SaveDrawingUseCase(repository: drawingRepository),
        exportDrawing: ExportDrawingUseCase(library: imageLibrary)
    )

    private lazy var drawingRepository: DrawingRepository = FileDrawingRepository.live()
    private lazy var imageLibrary: ImageLibrary = PhotoLibraryImageExporter()
}
