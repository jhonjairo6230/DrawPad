import Foundation

/// Guarda el dibujo en un archivo dentro del contenedor de la app.
///
/// Usa `Application Support`, que el sistema respalda pero no muestra en la
/// app Archivos. La fecha de guardado se conserva como fecha de modificación
/// del archivo, así no hace falta un archivo extra de metadatos.
final class FileDrawingRepository: DrawingRepository {
    static let fileName = "current.drawing"

    private let directory: URL
    private let fileManager: FileManager

    private var fileURL: URL { directory.appendingPathComponent(Self.fileName) }

    /// - Parameter directory: carpeta donde vive el archivo. Las pruebas pasan una temporal.
    init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    /// Repositorio real, en `Application Support/Drawings`.
    static func live(fileManager: FileManager = .default) -> FileDrawingRepository {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return FileDrawingRepository(
            directory: base.appendingPathComponent("Drawings", isDirectory: true),
            fileManager: fileManager
        )
    }

    func load() throws -> Drawing? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            let updatedAt = attributes[.modificationDate] as? Date ?? Date()
            return Drawing(strokesData: data, updatedAt: updatedAt)
        } catch {
            throw DrawingError.storageFailed
        }
    }

    func save(_ drawing: Drawing) throws {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            // `.atomic`: escribe en un temporal y lo renombra; si la app muere a
            // mitad, nunca queda un archivo corrupto.
            try drawing.strokesData.write(to: fileURL, options: .atomic)
            try fileManager.setAttributes(
                [.modificationDate: drawing.updatedAt],
                ofItemAtPath: fileURL.path
            )
        } catch {
            throw DrawingError.storageFailed
        }
    }
}
