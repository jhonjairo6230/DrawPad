import Foundation
@testable import DrawPad

/// Biblioteca falsa: guarda cuadernos y hojas en memoria y puede simular
/// fallos. Como la real, hace de repositorio de cuadernos y de hojas.
final class InMemoryLibrary: NotebookRepository, DrawingRepository {
    private(set) var notebooks: [UUID: Notebook] = [:]
    private(set) var drawings: [UUID: Drawing] = [:]
    var error: DrawingError?
    /// Veces que se guardó una hoja.
    private(set) var saveCount = 0

    init(notebooks: [Notebook] = [], drawings: [Drawing] = []) {
        for notebook in notebooks {
            self.notebooks[notebook.id] = notebook
        }
        for drawing in drawings {
            self.drawings[drawing.id] = drawing
        }
    }

    // MARK: - NotebookRepository

    func listNotebooks() throws -> [NotebookSummary] {
        if let error { throw error }
        return notebooks.values
            .map { notebook in
                let pages = pages(of: notebook.id)
                return NotebookSummary(
                    id: notebook.id,
                    title: notebook.title,
                    cover: notebook.cover,
                    pageCount: pages.count,
                    lastActivityAt: max(pages.map(\.updatedAt).max() ?? notebook.createdAt, notebook.createdAt)
                )
            }
            .sorted { $0.lastActivityAt > $1.lastActivityAt }
    }

    func findNotebook(id: UUID) throws -> Notebook? {
        if let error { throw error }
        return notebooks[id]
    }

    func save(_ notebook: Notebook) throws {
        if let error { throw error }
        notebooks[notebook.id] = notebook
    }

    func deleteNotebook(id: UUID) throws {
        if let error { throw error }
        notebooks[id] = nil
        for page in pages(of: id) {
            drawings[page.id] = nil
        }
    }

    // MARK: - DrawingRepository

    func listDrawings(notebookID: UUID) throws -> [DrawingSummary] {
        if let error { throw error }
        return pages(of: notebookID).map(\.summary)
    }

    func findDrawing(id: UUID) throws -> Drawing? {
        if let error { throw error }
        return drawings[id]
    }

    func save(_ drawing: Drawing) throws {
        if let error { throw error }
        drawings[drawing.id] = drawing
        saveCount += 1
    }

    func deleteDrawing(id: UUID) throws {
        if let error { throw error }
        drawings[id] = nil
    }

    // MARK: - Utilidades

    private func pages(of notebookID: UUID) -> [Drawing] {
        drawings.values
            .filter { $0.notebookID == notebookID }
            .sorted { $0.createdAt < $1.createdAt }
    }
}

extension Notebook {
    /// Cuaderno de ejemplo para las pruebas.
    static func sample(
        id: UUID = UUID(),
        title: String = "Cuaderno",
        createdAt: Date = Date(timeIntervalSince1970: 0),
        cover: NotebookCover = .standard
    ) -> Notebook {
        Notebook(id: id, title: title, createdAt: createdAt, cover: cover)
    }
}

extension Drawing {
    /// Hoja de ejemplo para las pruebas; cada una cambia solo lo que le importa.
    static func sample(
        id: UUID = UUID(),
        notebookID: UUID = UUID(),
        strokes: String = "",
        thumbnail: String? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        updatedAt: Date = Date(timeIntervalSince1970: 100),
        background: CanvasBackground = .blank,
        theme: CanvasTheme = .light
    ) -> Drawing {
        Drawing(
            id: id,
            notebookID: notebookID,
            strokesData: Data(strokes.utf8),
            thumbnailData: thumbnail.map { Data($0.utf8) },
            createdAt: createdAt,
            updatedAt: updatedAt,
            background: background,
            theme: theme
        )
    }
}
