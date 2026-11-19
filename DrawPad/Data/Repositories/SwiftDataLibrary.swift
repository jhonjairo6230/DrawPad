import Foundation
import SwiftData

/// Guarda cuadernos, hojas y sus elementos en una base de datos local con
/// SwiftData.
///
/// Implementa los tres puertos (``NotebookRepository``, ``DrawingRepository``
/// y ``PageElementRepository``) en una sola clase porque comparten **un mismo `ModelContext`**: dos
/// contextos distintos no ven al momento los cambios del otro, y operaciones
/// como "eliminar un cuaderno con sus hojas" tocan las dos tablas a la vez.
///
/// La base de datos vive dentro del contenedor de la app en el iPad
/// (`Application Support/default.store`); no sale del dispositivo.
///
/// Un contexto no se puede compartir entre hilos: aquí siempre se usa desde
/// el hilo principal, porque quien llama a los casos de uso son los ViewModel
/// (`@MainActor`).
final class SwiftDataLibrary: NotebookRepository, DrawingRepository, PageElementRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = ModelContext(container)
    }

    /// Crea el contenedor de la base de datos.
    /// - Parameter inMemory: `true` para una base de datos temporal que no
    ///   toca el disco (pruebas).
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: NotebookRecord.self, DrawingRecord.self, PageElementRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
        )
    }

    // MARK: - NotebookRepository

    func listNotebooks() throws -> [NotebookSummary] {
        try storage {
            try context.fetch(FetchDescriptor<NotebookRecord>())
                .map { notebook in
                    let pages = try pageRecords(notebookID: notebook.id)
                    return NotebookSummary(
                        id: notebook.id,
                        title: notebook.title,
                        cover: Self.cover(of: notebook),
                        pageCount: pages.count,
                        lastActivityAt: pages.map(\.updatedAt).max().map { max($0, notebook.createdAt) }
                            ?? notebook.createdAt
                    )
                }
                .sorted { $0.lastActivityAt > $1.lastActivityAt }
        }
    }

    func findNotebook(id: UUID) throws -> Notebook? {
        try storage {
            try notebookRecord(id: id).map {
                Notebook(id: $0.id, title: $0.title, createdAt: $0.createdAt, cover: Self.cover(of: $0))
            }
        }
    }

    func save(_ notebook: Notebook) throws {
        try storage {
            if let existing = try notebookRecord(id: notebook.id) {
                existing.title = notebook.title
                existing.coverColorRaw = notebook.cover.color.rawValue
                existing.coverStyleRaw = notebook.cover.style.rawValue
                existing.coverStrokesData = notebook.cover.drawing?.strokesData
                existing.coverImageData = notebook.cover.drawing?.imageData
            } else {
                let record = NotebookRecord(
                    id: notebook.id,
                    title: notebook.title,
                    createdAt: notebook.createdAt,
                    coverColorRaw: notebook.cover.color.rawValue,
                    coverStyleRaw: notebook.cover.style.rawValue
                )
                record.coverStrokesData = notebook.cover.drawing?.strokesData
                record.coverImageData = notebook.cover.drawing?.imageData
                context.insert(record)
            }
            try context.save()
        }
    }

    func deleteNotebook(id: UUID) throws {
        try storage {
            guard let notebook = try notebookRecord(id: id) else { return }
            for page in try pageRecords(notebookID: id) {
                try deleteElementRecords(pageID: page.id)
                context.delete(page)
            }
            context.delete(notebook)
            try context.save()
        }
    }

    // MARK: - DrawingRepository

    func listDrawings(notebookID: UUID) throws -> [DrawingSummary] {
        try storage {
            try pageRecords(notebookID: notebookID).map {
                DrawingSummary(id: $0.id, thumbnailData: $0.thumbnailData, updatedAt: $0.updatedAt)
            }
        }
    }

    func findDrawing(id: UUID) throws -> Drawing? {
        try storage {
            guard let record = try drawingRecord(id: id), let notebookID = record.notebookID else {
                return nil
            }
            return Drawing(
                id: record.id,
                notebookID: notebookID,
                strokesData: record.strokesData,
                thumbnailData: record.thumbnailData,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt,
                // Sin valor (hoja anterior a los fondos) o valor desconocido: papel blanco liso.
                background: record.backgroundRaw.flatMap(CanvasBackground.init(rawValue:)) ?? .blank,
                theme: record.themeRaw.flatMap(CanvasTheme.init(rawValue:)) ?? .light
            )
        }
    }

    func save(_ drawing: Drawing) throws {
        try storage {
            if let existing = try drawingRecord(id: drawing.id) {
                existing.strokesData = drawing.strokesData
                existing.thumbnailData = drawing.thumbnailData
                existing.updatedAt = drawing.updatedAt
                existing.backgroundRaw = drawing.background.rawValue
                existing.themeRaw = drawing.theme.rawValue
                existing.notebookID = drawing.notebookID
            } else {
                context.insert(DrawingRecord(
                    id: drawing.id,
                    strokesData: drawing.strokesData,
                    thumbnailData: drawing.thumbnailData,
                    createdAt: drawing.createdAt,
                    updatedAt: drawing.updatedAt,
                    backgroundRaw: drawing.background.rawValue,
                    themeRaw: drawing.theme.rawValue,
                    notebookID: drawing.notebookID
                ))
            }
            try context.save()
        }
    }

    func deleteDrawing(id: UUID) throws {
        try storage {
            guard let existing = try drawingRecord(id: id) else { return }
            try deleteElementRecords(pageID: id)
            context.delete(existing)
            try context.save()
        }
    }

    // MARK: - PageElementRepository

    func listElements(pageID: UUID) throws -> [PageElement] {
        try storage {
            try elementRecords(pageID: pageID).compactMap(Self.element)
        }
    }

    func findElement(id: UUID) throws -> PageElement? {
        try storage {
            try elementRecord(id: id).flatMap(Self.element)
        }
    }

    func save(_ element: PageElement) throws {
        try storage {
            let record: PageElementRecord
            if let existing = try elementRecord(id: element.id) {
                record = existing
            } else {
                record = PageElementRecord(
                    id: element.id,
                    pageID: element.pageID,
                    kindRaw: "",
                    text: nil,
                    imageData: nil,
                    x: 0,
                    y: 0,
                    width: 0,
                    height: 0,
                    createdAt: element.createdAt
                )
                context.insert(record)
            }
            Self.write(element, into: record)
            try context.save()
        }
    }

    func deleteElement(id: UUID) throws {
        try storage {
            guard let existing = try elementRecord(id: id) else { return }
            context.delete(existing)
            try context.save()
        }
    }

    // MARK: - Migración de datos

    /// Crea un cuaderno para cada dibujo guardado antes de que existieran los
    /// cuadernos: el dibujo pasa a ser su primera hoja y el cuaderno hereda
    /// su título. Se llama al arrancar; si no hay dibujos sueltos, no hace nada.
    func adoptOrphanDrawings() throws {
        try storage {
            let orphans = try context.fetch(FetchDescriptor<DrawingRecord>(
                predicate: #Predicate<DrawingRecord> { $0.notebookID == nil }
            ))
            guard !orphans.isEmpty else { return }
            for drawing in orphans {
                let notebook = NotebookRecord(
                    id: UUID(),
                    title: drawing.title.isEmpty ? "Cuaderno" : drawing.title,
                    createdAt: drawing.createdAt,
                    coverColorRaw: nil,
                    coverStyleRaw: nil
                )
                context.insert(notebook)
                drawing.notebookID = notebook.id
            }
            try context.save()
        }
    }

    // MARK: - Privado

    /// La tapa guardada. Sin valor (cuaderno anterior a las tapas) o con un
    /// valor desconocido, la tapa estándar.
    private static func cover(of record: NotebookRecord) -> NotebookCover {
        var drawing: CoverDrawing?
        if let strokes = record.coverStrokesData, let image = record.coverImageData {
            drawing = CoverDrawing(strokesData: strokes, imageData: image)
        }
        return NotebookCover(
            color: record.coverColorRaw.flatMap(CoverColor.init(rawValue:)) ?? NotebookCover.standard.color,
            style: record.coverStyleRaw.flatMap(CoverStyle.init(rawValue:)) ?? NotebookCover.standard.style,
            drawing: drawing
        )
    }

    private func notebookRecord(id: UUID) throws -> NotebookRecord? {
        var descriptor = FetchDescriptor<NotebookRecord>(predicate: #Predicate<NotebookRecord> { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func drawingRecord(id: UUID) throws -> DrawingRecord? {
        var descriptor = FetchDescriptor<DrawingRecord>(predicate: #Predicate<DrawingRecord> { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Las hojas de un cuaderno, de la primera a la última.
    private func pageRecords(notebookID: UUID) throws -> [DrawingRecord] {
        // El predicado compara dos opcionales: la columna puede estar vacía.
        let target: UUID? = notebookID
        return try context.fetch(FetchDescriptor<DrawingRecord>(
            predicate: #Predicate<DrawingRecord> { $0.notebookID == target },
            sortBy: [SortDescriptor(\.createdAt)]
        ))
    }

    private func elementRecord(id: UUID) throws -> PageElementRecord? {
        var descriptor = FetchDescriptor<PageElementRecord>(
            predicate: #Predicate<PageElementRecord> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Los elementos de una hoja, del más antiguo al más nuevo.
    private func elementRecords(pageID: UUID) throws -> [PageElementRecord] {
        try context.fetch(FetchDescriptor<PageElementRecord>(
            predicate: #Predicate<PageElementRecord> { $0.pageID == pageID },
            sortBy: [SortDescriptor(\.createdAt)]
        ))
    }

    /// Marca para borrar los elementos de una hoja (quien llama hace `save`).
    private func deleteElementRecords(pageID: UUID) throws {
        for element in try elementRecords(pageID: pageID) {
            context.delete(element)
        }
    }

    /// Copia en la fila todo lo del elemento, y vacía las columnas que su
    /// tipo no usa (por si antes era de otro tipo).
    private static func write(_ element: PageElement, into record: PageElementRecord) {
        record.x = element.frame.origin.x
        record.y = element.frame.origin.y
        record.width = element.frame.width
        record.height = element.frame.height
        record.text = nil
        record.imageData = nil
        record.shapeKindRaw = nil
        record.quarterTurns = nil
        record.fromID = nil
        record.toID = nil
        record.connectorStyleRaw = nil
        switch element.content {
        case .text(let value):
            record.kindRaw = PageElementRecord.textKind
            record.text = value
        case .image(let value):
            record.kindRaw = PageElementRecord.imageKind
            record.imageData = value
        case .shape(let shape):
            record.kindRaw = PageElementRecord.shapeKind
            record.text = shape.label
            record.shapeKindRaw = shape.kind.rawValue
            record.quarterTurns = shape.quarterTurns
        case .mermaid(let diagram):
            record.kindRaw = PageElementRecord.mermaidKind
            record.text = diagram.source
            record.imageData = diagram.image
        case .connector(let connector):
            record.kindRaw = PageElementRecord.connectorKind
            record.fromID = connector.fromID
            record.toID = connector.toID
            record.connectorStyleRaw = connector.style.rawValue
        }
    }

    /// La entidad de dominio, o `nil` si la fila no tiene el contenido que
    /// dice tener (no debería pasar; se ignora en lugar de romper la hoja).
    private static func element(from record: PageElementRecord) -> PageElement? {
        let content: PageElement.Content
        switch record.kindRaw {
        case PageElementRecord.textKind:
            guard let text = record.text else { return nil }
            content = .text(text)
        case PageElementRecord.imageKind:
            guard let data = record.imageData else { return nil }
            content = .image(data)
        case PageElementRecord.shapeKind:
            guard let kind = record.shapeKindRaw.flatMap(ShapeKind.init(rawValue:)) else { return nil }
            content = .shape(DiagramShape(
                kind: kind,
                label: record.text ?? "",
                quarterTurns: ((record.quarterTurns ?? 0) % 4 + 4) % 4
            ))
        case PageElementRecord.mermaidKind:
            guard let source = record.text, let image = record.imageData else { return nil }
            content = .mermaid(MermaidDiagram(source: source, image: image))
        case PageElementRecord.connectorKind:
            guard let fromID = record.fromID, let toID = record.toID else { return nil }
            content = .connector(Connector(
                fromID: fromID,
                toID: toID,
                style: record.connectorStyleRaw.flatMap(ConnectorStyle.init(rawValue:)) ?? .arrow
            ))
        default:
            return nil
        }
        return PageElement(
            id: record.id,
            pageID: record.pageID,
            frame: CGRect(x: record.x, y: record.y, width: record.width, height: record.height),
            content: content,
            createdAt: record.createdAt
        )
    }

    /// Traduce cualquier error de SwiftData al error de dominio.
    private func storage<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch {
            throw DrawingError.storageFailed
        }
    }
}
