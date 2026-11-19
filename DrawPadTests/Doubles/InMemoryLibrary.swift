import Foundation
@testable import DrawPad

/// Biblioteca falsa: guarda cuadernos, hojas y elementos en memoria y puede
/// simular fallos. Como la real, hace de los tres repositorios.
final class InMemoryLibrary: NotebookRepository, DrawingRepository, PageElementRepository {
    private(set) var notebooks: [UUID: Notebook] = [:]
    private(set) var drawings: [UUID: Drawing] = [:]
    private(set) var elements: [UUID: PageElement] = [:]
    var error: DrawingError?
    /// Veces que se guardó una hoja.
    private(set) var saveCount = 0

    init(notebooks: [Notebook] = [], drawings: [Drawing] = [], elements: [PageElement] = []) {
        for element in elements {
            self.elements[element.id] = element
        }
        for notebook in notebooks {
            self.notebooks[notebook.id] = notebook
        }
        for drawing in drawings {
            self.drawings[drawing.id] = drawing
        }
    }

    // MARK: - NotebookRepository

    func listNotebooks() throws -> [NotebookSummary] {
        if let error { throw error }
        return notebooks.values
            .map { notebook in
                let pages = pages(of: notebook.id)
                return NotebookSummary(
                    id: notebook.id,
                    title: notebook.title,
                    cover: notebook.cover,
                    pageCount: pages.count,
                    lastActivityAt: max(pages.map(\.updatedAt).max() ?? notebook.createdAt, notebook.createdAt)
                )
            }
            .sorted { $0.lastActivityAt > $1.lastActivityAt }
    }

    func findNotebook(id: UUID) throws -> Notebook? {
        if let error { throw error }
        return notebooks[id]
    }

    func save(_ notebook: Notebook) throws {
        if let error { throw error }
        notebooks[notebook.id] = notebook
    }

    func deleteNotebook(id: UUID) throws {
        if let error { throw error }
        notebooks[id] = nil
        for page in pages(of: id) {
            drawings[page.id] = nil
            removeElements(of: page.id)
        }
    }

    // MARK: - DrawingRepository

    func listDrawings(notebookID: UUID) throws -> [DrawingSummary] {
        if let error { throw error }
        return pages(of: notebookID).map(\.summary)
    }

    func findDrawing(id: UUID) throws -> Drawing? {
        if let error { throw error }
        return drawings[id]
    }

    func save(_ drawing: Drawing) throws {
        if let error { throw error }
        drawings[drawing.id] = drawing
        saveCount += 1
    }

    func deleteDrawing(id: UUID) throws {
        if let error { throw error }
        drawings[id] = nil
        removeElements(of: id)
    }

    // MARK: - PageElementRepository

    func listElements(pageID: UUID) throws -> [PageElement] {
        if let error { throw error }
        return elements.values
            .filter { $0.pageID == pageID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func findElement(id: UUID) throws -> PageElement? {
        if let error { throw error }
        return elements[id]
    }

    func save(_ element: PageElement) throws {
        if let error { throw error }
        elements[element.id] = element
    }

    func deleteElement(id: UUID) throws {
        if let error { throw error }
        elements[id] = nil
    }

    // MARK: - Utilidades

    private func removeElements(of pageID: UUID) {
        elements = elements.filter { $0.value.pageID != pageID }
    }

    private func pages(of notebookID: UUID) -> [Drawing] {
        drawings.values
            .filter { $0.notebookID == notebookID }
            .sorted { $0.createdAt < $1.createdAt }
    }
}

extension Notebook {
    /// Cuaderno de ejemplo para las pruebas.
    static func sample(
        id: UUID = UUID(),
        title: String = "Cuaderno",
        createdAt: Date = Date(timeIntervalSince1970: 0),
        cover: NotebookCover = .standard
    ) -> Notebook {
        Notebook(id: id, title: title, createdAt: createdAt, cover: cover)
    }
}

extension PageElement {
    /// Cuadro de texto de ejemplo para las pruebas.
    static func sampleText(
        id: UUID = UUID(),
        pageID: UUID = UUID(),
        _ text: String = "Hola",
        frame: CGRect = CGRect(x: 10, y: 20, width: 320, height: 28),
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) -> PageElement {
        PageElement(id: id, pageID: pageID, frame: frame, content: .text(text), createdAt: createdAt)
    }

    /// Imagen de ejemplo para las pruebas (los datos no son una imagen real).
    static func sampleImage(
        id: UUID = UUID(),
        pageID: UUID = UUID(),
        data: String = "imagen",
        frame: CGRect = CGRect(x: 50, y: 60, width: 200, height: 100),
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) -> PageElement {
        PageElement(id: id, pageID: pageID, frame: frame, content: .image(Data(data.utf8)), createdAt: createdAt)
    }
}

extension PageElement {
    /// Figura de ejemplo para las pruebas.
    static func sampleShape(
        id: UUID = UUID(),
        pageID: UUID = UUID(),
        _ kind: ShapeKind = .rectangle,
        label: String = "",
        quarterTurns: Int = 0,
        frame: CGRect = CGRect(x: 100, y: 100, width: 160, height: 100),
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) -> PageElement {
        PageElement(
            id: id,
            pageID: pageID,
            frame: frame,
            content: .shape(DiagramShape(kind: kind, label: label, quarterTurns: quarterTurns)),
            createdAt: createdAt
        )
    }

    /// Conexión de ejemplo para las pruebas.
    static func sampleConnector(
        id: UUID = UUID(),
        pageID: UUID = UUID(),
        from fromID: UUID,
        to toID: UUID,
        style: ConnectorStyle = .arrow,
        createdAt: Date = Date(timeIntervalSince1970: 10)
    ) -> PageElement {
        PageElement(
            id: id,
            pageID: pageID,
            frame: .zero,
            content: .connector(Connector(fromID: fromID, toID: toID, style: style)),
            createdAt: createdAt
        )
    }
}

extension Drawing {
    /// Hoja de ejemplo para las pruebas; cada una cambia solo lo que le importa.
    static func sample(
        id: UUID = UUID(),
        notebookID: UUID = UUID(),
        strokes: String = "",
        thumbnail: String? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        updatedAt: Date = Date(timeIntervalSince1970: 100),
        background: CanvasBackground = .blank,
        theme: CanvasTheme = .light
    ) -> Drawing {
        Drawing(
            id: id,
            notebookID: notebookID,
            strokesData: Data(strokes.utf8),
            thumbnailData: thumbnail.map { Data($0.utf8) },
            createdAt: createdAt,
            updatedAt: updatedAt,
            background: background,
            theme: theme
        )
    }
}
