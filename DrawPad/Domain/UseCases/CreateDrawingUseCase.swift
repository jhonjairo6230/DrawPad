import Foundation

/// Crea un dibujo vacío con un título por defecto ("Dibujo 3").
struct CreateDrawingUseCase {
    private let repository: DrawingRepository
    private let now: () -> Date
    private let makeID: () -> UUID

    /// - Parameters:
    ///   - now: reloj inyectable para las pruebas.
    ///   - makeID: generador de identificadores inyectable para las pruebas.
    init(
        repository: DrawingRepository,
        now: @escaping () -> Date = Date.init,
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.repository = repository
        self.now = now
        self.makeID = makeID
    }

    func execute() throws -> Drawing {
        let number = try repository.list().count + 1
        let date = now()
        let drawing = Drawing(
            id: makeID(),
            title: "Dibujo \(number)",
            strokesData: Data(),
            thumbnailData: nil,
            createdAt: date,
            updatedAt: date
        )
        try repository.save(drawing)
        return drawing
    }
}
