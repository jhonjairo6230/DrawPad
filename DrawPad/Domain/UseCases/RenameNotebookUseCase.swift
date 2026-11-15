import Foundation

/// Cambia el título de un cuaderno.
struct RenameNotebookUseCase {
    private let notebooks: NotebookRepository

    init(notebooks: NotebookRepository) {
        self.notebooks = notebooks
    }

    /// - Throws: ``DrawingError/invalidTitle`` si el título queda vacío al
    ///   quitar espacios, o ``DrawingError/notebookNotFound``.
    func execute(id: UUID, title: String) throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DrawingError.invalidTitle }
        guard var notebook = try notebooks.findNotebook(id: id) else {
            throw DrawingError.notebookNotFound
        }
        notebook.title = trimmed
        try notebooks.save(notebook)
    }
}
