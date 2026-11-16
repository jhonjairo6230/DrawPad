import Foundation

/// Cambia la tapa de un cuaderno (color y estilo).
struct ChangeCoverUseCase {
    private let notebooks: NotebookRepository

    init(notebooks: NotebookRepository) {
        self.notebooks = notebooks
    }

    /// - Throws: ``DrawingError/notebookNotFound`` si el cuaderno ya no existe.
    func execute(id: UUID, cover: NotebookCover) throws {
        guard var notebook = try notebooks.findNotebook(id: id) else {
            throw DrawingError.notebookNotFound
        }
        notebook.cover = cover
        try notebooks.save(notebook)
    }
}
