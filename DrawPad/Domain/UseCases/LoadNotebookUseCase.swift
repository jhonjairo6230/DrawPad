import Foundation

/// Recupera un cuaderno para abrirlo.
struct LoadNotebookUseCase {
    private let notebooks: NotebookRepository

    init(notebooks: NotebookRepository) {
        self.notebooks = notebooks
    }

    /// - Throws: ``DrawingError/notebookNotFound`` si el cuaderno no existe.
    func execute(id: UUID) throws -> Notebook {
        guard let notebook = try notebooks.findNotebook(id: id) else {
            throw DrawingError.notebookNotFound
        }
        return notebook
    }
}
