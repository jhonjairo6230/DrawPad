import Foundation

/// Elimina un cuaderno con todas sus hojas, de forma definitiva.
struct DeleteNotebookUseCase {
    private let notebooks: NotebookRepository

    init(notebooks: NotebookRepository) {
        self.notebooks = notebooks
    }

    func execute(id: UUID) throws {
        try notebooks.deleteNotebook(id: id)
    }
}
