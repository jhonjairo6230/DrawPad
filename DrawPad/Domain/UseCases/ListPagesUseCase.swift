import Foundation

/// Lista las hojas de un cuaderno, de la primera a la última.
struct ListPagesUseCase {
    private let drawings: DrawingRepository

    init(drawings: DrawingRepository) {
        self.drawings = drawings
    }

    func execute(notebookID: UUID) throws -> [DrawingSummary] {
        try drawings.listDrawings(notebookID: notebookID)
    }
}
