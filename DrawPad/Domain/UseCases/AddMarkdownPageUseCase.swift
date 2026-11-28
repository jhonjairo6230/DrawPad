import Foundation

/// Añade una hoja Markdown al final de un cuaderno.
struct AddMarkdownPageUseCase {
    /// Con lo que empieza una hoja Markdown nueva: un esquema de spec.
    static let template = """
    # Título

    ## Contexto

    Qué problema hay y por qué importa.

    ## Propuesta

    - Punto 1
    - Punto 2

    ```mermaid
    flowchart LR
        A[Cliente] --> B[API]
    ```

    ## Tareas

    - [ ] Primera tarea
    - [ ] Segunda tarea
    """

    private let drawings: DrawingRepository
    private let now: () -> Date
    private let makeID: () -> UUID

    init(
        drawings: DrawingRepository,
        now: @escaping () -> Date = Date.init,
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.drawings = drawings
        self.now = now
        self.makeID = makeID
    }

    /// - Parameter markdown: el texto inicial; por defecto, ``template``.
    func execute(notebookID: UUID, markdown: String = Self.template) throws -> Drawing {
        let date = now()
        let page = Drawing(
            id: makeID(),
            notebookID: notebookID,
            strokesData: Data(),
            thumbnailData: nil,
            createdAt: date,
            updatedAt: date,
            kind: .markdown,
            markdown: markdown
        )
        try drawings.save(page)
        return page
    }
}
