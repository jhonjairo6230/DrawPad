import Foundation

/// Crea un cuaderno con un título por defecto ("Cuaderno 3") y su primera
/// hoja en blanco: un cuaderno nunca está sin hojas.
struct CreateNotebookUseCase {
    private let notebooks: NotebookRepository
    private let drawings: DrawingRepository
    private let now: () -> Date
    private let makeID: () -> UUID

    /// - Parameters:
    ///   - now: reloj inyectable para las pruebas.
    ///   - makeID: generador de identificadores inyectable para las pruebas.
    init(
        notebooks: NotebookRepository,
        drawings: DrawingRepository,
        now: @escaping () -> Date = Date.init,
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.notebooks = notebooks
        self.drawings = drawings
        self.now = now
        self.makeID = makeID
    }

    func execute() throws -> Notebook {
        let number = try notebooks.listNotebooks().count + 1
        let date = now()
        let notebook = Notebook(id: makeID(), title: "Cuaderno \(number)", createdAt: date)
        try notebooks.save(notebook)
        try drawings.save(Drawing(
            id: makeID(),
            notebookID: notebook.id,
            strokesData: Data(),
            thumbnailData: nil,
            createdAt: date,
            updatedAt: date
        ))
        return notebook
    }
}
