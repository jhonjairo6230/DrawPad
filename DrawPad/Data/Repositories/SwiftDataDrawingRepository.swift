import Foundation
import SwiftData

/// Guarda los dibujos en una base de datos local con SwiftData.
///
/// La base de datos vive dentro del contenedor de la app en el iPad
/// (`Application Support/default.store`); no sale del dispositivo.
///
/// Usa un `ModelContext` propio. Un contexto no se puede compartir entre
/// hilos: aquí siempre se usa desde el hilo principal, porque quien llama a
/// los casos de uso son los ViewModel (`@MainActor`).
final class SwiftDataDrawingRepository: DrawingRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = ModelContext(container)
    }

    /// Crea el contenedor de la base de datos.
    /// - Parameter inMemory: `true` para una base de datos temporal que no
    ///   toca el disco (pruebas).
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: DrawingRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
        )
    }

    func list() throws -> [DrawingSummary] {
        try storage {
            let descriptor = FetchDescriptor<DrawingRecord>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            return try context.fetch(descriptor).map {
                DrawingSummary(id: $0.id, title: $0.title, thumbnailData: $0.thumbnailData, updatedAt: $0.updatedAt)
            }
        }
    }

    func find(id: UUID) throws -> Drawing? {
        try storage {
            try record(id: id).map {
                Drawing(
                    id: $0.id,
                    title: $0.title,
                    strokesData: $0.strokesData,
                    thumbnailData: $0.thumbnailData,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
                    // Sin valor (dibujo anterior a los fondos) o valor desconocido: papel blanco liso.
                    background: $0.backgroundRaw.flatMap(CanvasBackground.init(rawValue:)) ?? .blank,
                    theme: $0.themeRaw.flatMap(CanvasTheme.init(rawValue:)) ?? .light
                )
            }
        }
    }

    func save(_ drawing: Drawing) throws {
        try storage {
            if let existing = try record(id: drawing.id) {
                existing.title = drawing.title
                existing.strokesData = drawing.strokesData
                existing.thumbnailData = drawing.thumbnailData
                existing.updatedAt = drawing.updatedAt
                existing.backgroundRaw = drawing.background.rawValue
                existing.themeRaw = drawing.theme.rawValue
            } else {
                context.insert(DrawingRecord(
                    id: drawing.id,
                    title: drawing.title,
                    strokesData: drawing.strokesData,
                    thumbnailData: drawing.thumbnailData,
                    createdAt: drawing.createdAt,
                    updatedAt: drawing.updatedAt,
                    backgroundRaw: drawing.background.rawValue,
                    themeRaw: drawing.theme.rawValue
                ))
            }
            try context.save()
        }
    }

    func delete(id: UUID) throws {
        try storage {
            guard let existing = try record(id: id) else { return }
            context.delete(existing)
            try context.save()
        }
    }

    // MARK: - Privado

    private func record(id: UUID) throws -> DrawingRecord? {
        var descriptor = FetchDescriptor<DrawingRecord>(predicate: #Predicate<DrawingRecord> { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
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
