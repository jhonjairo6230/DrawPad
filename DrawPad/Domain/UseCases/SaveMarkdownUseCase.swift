import Foundation

/// Guarda el texto de una hoja Markdown.
struct SaveMarkdownUseCase {
    private let drawings: DrawingRepository
    private let now: () -> Date

    init(drawings: DrawingRepository, now: @escaping () -> Date = Date.init) {
        self.drawings = drawings
        self.now = now
    }

    /// El texto se guarda tal cual (sin recortar): en Markdown los espacios y
    /// los saltos de línea cuentan.
    /// - Throws: ``DrawingError/drawingNotFound`` si la hoja no existe o no es
    ///   de Markdown.
    func execute(id: UUID, markdown: String) throws {
        guard var page = try drawings.findDrawing(id: id), page.kind == .markdown else {
            throw DrawingError.drawingNotFound
        }
        page.markdown = markdown
        page.updatedAt = now()
        try drawings.save(page)
    }
}
