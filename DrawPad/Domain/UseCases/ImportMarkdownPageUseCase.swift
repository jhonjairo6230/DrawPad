import Foundation

/// Trae un archivo `.md` como hoja Markdown nueva al final de un cuaderno.
struct ImportMarkdownPageUseCase {
    private let reader: ImportedFileReader
    private let addPage: AddMarkdownPageUseCase

    init(reader: ImportedFileReader, addPage: AddMarkdownPageUseCase) {
        self.reader = reader
        self.addPage = addPage
    }

    /// - Throws: ``DrawingError/importFailed`` si no se puede leer o no es
    ///   texto (UTF-8).
    func execute(notebookID: UUID, fileURL: URL) throws -> Drawing {
        let data = try reader.read(fileURL)
        guard let text = String(data: data, encoding: .utf8) else {
            throw DrawingError.importFailed
        }
        return try addPage.execute(notebookID: notebookID, markdown: text)
    }
}
