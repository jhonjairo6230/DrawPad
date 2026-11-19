import Foundation
import SwiftData
import UIKit

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
    /// Las pruebas de interfaz corren en un simulador de iPad: con este
    /// argumento la app se comporta como en el iPhone (solo lectura).
    static let readOnlyArgument = "-readOnly"
    /// Con este argumento (y `-uiTesting`) la app arranca con un cuaderno de
    /// ejemplo, para probar la lectura sin poder crear cuadernos.
    static let sampleNotebookArgument = "-uiTestingSampleNotebook"
    /// Lo que "hay en el portapapeles" durante las pruebas de interfaz.
    static let uiTestingClipboardText = "Texto pegado"

    private let isUITesting = ProcessInfo.processInfo.arguments.contains(AppContainer.uiTestingArgument)

    /// `false` en el iPhone: la app solo lee (ver docs/adr/0018).
    private(set) lazy var canEdit: Bool = UIDevice.current.userInterfaceIdiom != .phone
        && !ProcessInfo.processInfo.arguments.contains(AppContainer.readOnlyArgument)

    private(set) lazy var galleryViewModel = GalleryViewModel(
        listNotebooks: ListNotebooksUseCase(notebooks: library),
        createNotebook: CreateNotebookUseCase(notebooks: library, drawings: library),
        renameNotebook: RenameNotebookUseCase(notebooks: library),
        deleteNotebook: DeleteNotebookUseCase(notebooks: library),
        changeCover: ChangeCoverUseCase(notebooks: library),
        exportNotebook: ExportNotebookUseCase(
            notebooks: library, drawings: library, elements: library,
            coder: archiveCoder, store: exportFileStore
        ),
        importNotebook: ImportNotebookUseCase(
            notebooks: library, drawings: library, elements: library,
            coder: archiveCoder, reader: SecurityScopedFileReader()
        )
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

    /// Monta la pantalla para dibujar una portada: un lienzo nuevo y su ViewModel.
    func makeCoverDrawingModule(initialDrawing: CoverDrawing?, color: CoverColor) -> CoverDrawingModule {
        let canvas = PencilKitCanvas()
        let viewModel = CoverDrawingViewModel(
            canvas: canvas,
            initialDrawing: initialDrawing,
            color: color,
            preferences: canvasPreferences
        )
        return CoverDrawingModule(viewModel: viewModel, canvas: canvas)
    }

    /// Monta la pantalla de una hoja: un lienzo nuevo y su ViewModel.
    func makeCanvasModule(drawingID: UUID, shareName: String) -> CanvasModule {
        let canvas = PencilKitCanvas(isReadOnly: !canEdit)
        let viewModel = CanvasViewModel(
            drawingID: drawingID,
            shareName: shareName,
            preferences: canvasPreferences,
            canvas: canvas,
            loadDrawing: LoadDrawingUseCase(repository: library),
            saveDrawing: SaveDrawingUseCase(repository: library),
            changeBackground: ChangeBackgroundUseCase(repository: library),
            exportDrawing: ExportDrawingUseCase(library: imageLibrary),
            prepareShareFile: PrepareShareFileUseCase(store: exportFileStore),
            elementUseCases: PageElementUseCases(elements: library, clipboard: clipboard)
        )
        return CanvasModule(viewModel: viewModel, canvas: canvas) { source, theme in
            let preview = WebKitMermaidPreview()
            let editor = MermaidEditorViewModel(source: source, theme: theme, preview: preview)
            return MermaidEditorModule(viewModel: editor, preview: preview)
        }
    }

    // MARK: - Implementaciones concretas

    /// La base de datos: sirve de repositorio de cuadernos y de hojas.
    private lazy var library: SwiftDataLibrary = {
        do {
            let container = try SwiftDataLibrary.makeContainer(inMemory: isUITesting)
            let library = SwiftDataLibrary(container: container)
            // Dibujos guardados antes de que existieran los cuadernos.
            try library.adoptOrphanDrawings()
            if isUITesting, ProcessInfo.processInfo.arguments.contains(AppContainer.sampleNotebookArgument) {
                try AppContainer.addSampleNotebook(to: library)
            }
            return library
        } catch {
            // Sin base de datos la app no puede hacer nada útil.
            fatalError("No se pudo abrir la base de datos: \(error)")
        }
    }()

    /// "Cuaderno 1" con dos hojas y un texto en la primera.
    private static func addSampleNotebook(to library: SwiftDataLibrary) throws {
        let notebook = try CreateNotebookUseCase(notebooks: library, drawings: library).execute()
        let firstPage = try ListPagesUseCase(drawings: library).execute(notebookID: notebook.id)[0]
        _ = try AddTextElementUseCase(elements: library)
            .execute(pageID: firstPage.id, text: "Hola desde el iPad", centeredAt: CGPoint(x: 260, y: 200))
        _ = try AddPageUseCase(drawings: library).execute(notebookID: notebook.id)
    }

    private lazy var canvasPreferences = CanvasPreferences()
    private lazy var imageLibrary: ImageLibrary = PhotoLibraryImageExporter()
    private lazy var exportFileStore: ExportFileStore = TemporaryExportFileStore.live()
    private lazy var archiveCoder: NotebookArchiveCoder = JSONNotebookArchiveCoder()
    /// En las pruebas de interfaz, un portapapeles fijo: leer el del sistema
    /// muestra un aviso de permiso de iOS que una prueba no puede aceptar.
    private lazy var clipboard: Clipboard = isUITesting
        ? FixedClipboard(content: .text(AppContainer.uiTestingClipboardText))
        : SystemClipboard()
}
