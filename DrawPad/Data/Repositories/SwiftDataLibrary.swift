import Foundation
import SwiftData

/// Guarda cuadernos y hojas en una base de datos local con SwiftData.
///
/// Implementa los dos puertos (``NotebookRepository`` y ``DrawingRepository``)
/// en una sola clase porque comparten **un mismo `ModelContext`**: dos
/// contextos distintos no ven al momento los cambios del otro, y operaciones
/// como "eliminar un cuaderno con sus hojas" tocan las dos tablas a la vez.
///
/// La base de datos vive dentro del contenedor de la app en el iPad
/// (`Application Support/default.store`); no sale del dispositivo.
///
/// Un contexto no se puede compartir entre hilos: aquí siempre se usa desde
/// el hilo principal, porque quien llama a los casos de uso son los ViewModel
/// (`@MainActor`).
final class SwiftDataLibrary: NotebookRepository, DrawingRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = ModelContext(container)
    }

    /// Crea el contenedor de la base de datos.
    /// - Parameter inMemory: `true` para una base de datos temporal que no
    ///   toca el disco (pruebas).
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: NotebookRecord.self, DrawingRecord.self,
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
            } else {
                context.insert(NotebookRecord(
                    id: notebook.id,
                    title: notebook.title,
                    createdAt: notebook.createdAt,
                    coverColorRaw: notebook.cover.color.rawValue,
                    coverStyleRaw: notebook.cover.style.rawValue
                ))
            }
            try context.save()
        }
    }

    func deleteNotebook(id: UUID) throws {
        try storage {
            guard let notebook = try notebookRecord(id: id) else { return }
            for page in try pageRecords(notebookID: id) {
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
        NotebookCover(
            color: record.coverColorRaw.flatMap(CoverColor.init(rawValue:)) ?? NotebookCover.standard.color,
            style: record.coverStyleRaw.flatMap(CoverStyle.init(rawValue:)) ?? NotebookCover.standard.style
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

    /// Traduce cualquier error de SwiftData al error de dominio.
    private func storage<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch {
            throw DrawingError.storageFailed
        }
    }
}
