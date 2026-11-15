import Foundation

/// Lista los dibujos para la galería, del más reciente al más antiguo.
struct ListDrawingsUseCase {
    private let repository: DrawingRepository

    init(repository: DrawingRepository) {
        self.repository = repository
    }

    func execute() throws -> [DrawingSummary] {
        try repository.list()
    }
}
