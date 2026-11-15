import Foundation
import SwiftData

/// *Composition root*: el único lugar donde se crean las implementaciones
/// concretas y se conectan entre sí (inyección de dependencias manual).
///
/// El resto del código solo conoce protocolos. Para cambiar, por ejemplo, el
/// almacenamiento a iCloud, bastaría con cambiar una línea aquí.
///
/// **Todo es `lazy` a propósito.** `DrawPadApp.init()` se ejecuta antes de que
/// exista `UIApplication`; un `PKCanvasView` creado tan pronto deja sus gestos
/// mal inicializados y la app se cierra al primer toque con el dedo. Aquí las
/// cosas se crean cuando la escena las pide por primera vez.
@MainActor
final class AppContainer {
    /// Argumento de lanzamiento que usan las pruebas de interfaz para arrancar
    /// con una base de datos vacía y en memoria.
    static let uiTestingArgument = "-uiTesting"

    private let isUITesting = ProcessInfo.processInfo.arguments.contains(AppContainer.uiTestingArgument)

    private(set) lazy var galleryViewModel = GalleryViewModel(
        listDrawings: ListDrawingsUseCase(repository: drawingRepository),
        createDrawing: CreateDrawingUseCase(repository: drawingRepository),
        renameDrawing: RenameDrawingUseCase(repository: drawingRepository),
        deleteDrawing: DeleteDrawingUseCase(repository: drawingRepository)
    )

    /// Monta la pantalla de un dibujo: un lienzo nuevo y su ViewModel.
    func makeCanvasModule(drawingID: UUID) -> CanvasModule {
        let canvas = PencilKitCanvas()
        let viewModel = CanvasViewModel(
            drawingID: drawingID,
            canvas: canvas,
            loadDrawing: LoadDrawingUseCase(repository: drawingRepository),
            saveDrawing: SaveDrawingUseCase(repository: drawingRepository),
            changeBackground: ChangeBackgroundUseCase(repository: drawingRepository),
            exportDrawing: ExportDrawingUseCase(library: imageLibrary)
        )
        return CanvasModule(viewModel: viewModel, canvas: canvas)
    }

    // MARK: - Implementaciones concretas

    private lazy var drawingRepository: DrawingRepository = {
        let container: ModelContainer
        do {
            container = try SwiftDataDrawingRepository.makeContainer(inMemory: isUITesting)
        } catch {
            // Sin base de datos la app no puede hacer nada útil.
            fatalError("No se pudo abrir la base de datos: \(error)")
        }
        let repository = SwiftDataDrawingRepository(container: container)
        if !isUITesting {
            LegacyDrawingFileImporter.live().importIfNeeded(into: repository)
        }
        return repository
    }()

    private lazy var imageLibrary: ImageLibrary = PhotoLibraryImageExporter()
}
