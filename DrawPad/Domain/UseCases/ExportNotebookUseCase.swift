import Foundation

/// Exporta un cuaderno completo a un archivo que DrawPad sabe volver a abrir
/// (en este u otro dispositivo).
struct ExportNotebookUseCase {
    private let notebooks: NotebookRepository
    private let drawings: DrawingRepository
    private let elements: PageElementRepository
    private let coder: NotebookArchiveCoder
    private let store: ExportFileStore

    init(
        notebooks: NotebookRepository,
        drawings: DrawingRepository,
        elements: PageElementRepository,
        coder: NotebookArchiveCoder,
        store: ExportFileStore
    ) {
        self.notebooks = notebooks
        self.drawings = drawings
        self.elements = elements
        self.coder = coder
        self.store = store
    }

    /// - Returns: dónde quedó el archivo, listo para compartir ("Física.drawpad").
    /// - Throws: ``DrawingError/notebookNotFound`` si el cuaderno no existe, o
    ///   los errores del almacenamiento y del formato.
    func execute(id: UUID) throws -> URL {
        let bundle = try makeBundle(notebookID: id)
        let data = try coder.encode(bundle)
        let name = PrepareShareFileUseCase.safeFileName(from: bundle.notebook.title)
        return try store.write(data, fileName: "\(name).\(coder.fileExtension)")
    }

    func makeBundle(notebookID: UUID) throws -> NotebookBundle {
        guard let notebook = try notebooks.findNotebook(id: notebookID) else {
            throw DrawingError.notebookNotFound
        }
        let pages = try drawings.listDrawings(notebookID: notebookID).map { summary in
            guard let page = try drawings.findDrawing(id: summary.id) else {
                throw DrawingError.drawingNotFound
            }
            return page
        }
        let pageElements = try pages.flatMap { try elements.listElements(pageID: $0.id) }
        return NotebookBundle(notebook: notebook, pages: pages, elements: pageElements)
    }
}
