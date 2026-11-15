import Foundation

/// Lista los cuadernos para la galería, del usado más recientemente al más antiguo.
struct ListNotebooksUseCase {
    private let notebooks: NotebookRepository

    init(notebooks: NotebookRepository) {
        self.notebooks = notebooks
    }

    func execute() throws -> [NotebookSummary] {
        try notebooks.listNotebooks()
    }
}
