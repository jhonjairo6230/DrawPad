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
        listNotebooks: ListNotebooksUseCase(notebooks: library),
        createNotebook: CreateNotebookUseCase(notebooks: library, drawings: library),
        renameNotebook: RenameNotebookUseCase(notebooks: library),
        deleteNotebook: DeleteNotebookUseCase(notebooks: library),
        changeCover: ChangeCoverUseCase(notebooks: library)
    )

    /// Monta un cuaderno abierto. Cada hoja que muestre la crea con
    /// ``makeCanvasModule(drawingID:shareName:)``.
    func makeNotebookViewModel(notebookID: UUID) -> NotebookViewModel {
        NotebookViewModel(
            notebookID: notebookID,
            loadNotebook: LoadNotebookUseCase(notebooks: library),
            listPages: ListPagesUseCase(drawings: library),
            addPage: AddPageUseCase(drawings: library),
            deletePage: DeletePageUseCase(drawings: library),
            makeSession: { [unowned self] pageID, shareName in
                makeCanvasModule(drawingID: pageID, shareName: shareName)
            }
        )
    }

    /// Monta la pantalla de una hoja: un lienzo nuevo y su ViewModel.
    func makeCanvasModule(drawingID: UUID, shareName: String) -> CanvasModule {
        let canvas = PencilKitCanvas()
        let viewModel = CanvasViewModel(
            drawingID: drawingID,
            shareName: shareName,
            preferences: canvasPreferences,
            canvas: canvas,
            loadDrawing: LoadDrawingUseCase(repository: library),
            saveDrawing: SaveDrawingUseCase(repository: library),
            changeBackground: ChangeBackgroundUseCase(repository: library),
            exportDrawing: ExportDrawingUseCase(library: imageLibrary),
            prepareShareFile: PrepareShareFileUseCase(store: exportFileStore)
        )
        return CanvasModule(viewModel: viewModel, canvas: canvas)
    }

    // MARK: - Implementaciones concretas

    /// La base de datos: sirve de repositorio de cuadernos y de hojas.
    private lazy var library: SwiftDataLibrary = {
        do {
            let container = try SwiftDataLibrary.makeContainer(inMemory: isUITesting)
            let library = SwiftDataLibrary(container: container)
            // Dibujos guardados antes de que existieran los cuadernos.
            try library.adoptOrphanDrawings()
            return library
        } catch {
            // Sin base de datos la app no puede hacer nada útil.
            fatalError("No se pudo abrir la base de datos: \(error)")
        }
    }()

    private lazy var canvasPreferences = CanvasPreferences()
    private lazy var imageLibrary: ImageLibrary = PhotoLibraryImageExporter()
    private lazy var exportFileStore: ExportFileStore = TemporaryExportFileStore.live()
}
