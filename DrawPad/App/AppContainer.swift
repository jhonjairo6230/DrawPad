import Foundation

/// *Composition root*: el único lugar donde se crean las implementaciones
/// concretas y se conectan entre sí (inyección de dependencias manual).
///
/// El resto del código solo conoce protocolos. Para cambiar, por ejemplo, el
/// almacenamiento a iCloud, bastaría con cambiar una línea aquí.
@MainActor
final class AppContainer {
    let canvas = PencilKitCanvas()

    private let drawingRepository: DrawingRepository = FileDrawingRepository.live()
    private let imageLibrary: ImageLibrary = PhotoLibraryImageExporter()

    func makeCanvasViewModel() -> CanvasViewModel {
        CanvasViewModel(
            canvas: canvas,
            loadDrawing: LoadDrawingUseCase(repository: drawingRepository),
            saveDrawing: SaveDrawingUseCase(repository: drawingRepository),
            exportDrawing: ExportDrawingUseCase(library: imageLibrary)
        )
    }
}
