import Foundation

/// Exporta una hoja Markdown como archivo `.md` para abrirlo en otras apps.
struct ExportMarkdownUseCase {
    private let drawings: DrawingRepository
    private let store: ExportFileStore

    init(drawings: DrawingRepository, store: ExportFileStore) {
        self.drawings = drawings
        self.store = store
    }

    /// - Parameter name: nombre del archivo, sin extensión ("Física - Hoja 2").
    /// - Throws: ``DrawingError/drawingNotFound`` si la hoja no existe o no es
    ///   de Markdown.
    func execute(id: UUID, name: String) throws -> URL {
        guard let page = try drawings.findDrawing(id: id), page.kind == .markdown else {
            throw DrawingError.drawingNotFound
        }
        let fileName = "\(PrepareShareFileUseCase.safeFileName(from: name)).md"
        return try store.write(Data(page.markdown.utf8), fileName: fileName)
    }
}
