import Foundation

/// Trae a la base de datos el dibujo de la primera versión de la app.
///
/// Antes de la galería había un único dibujo, guardado en el archivo
/// `Application Support/Drawings/current.drawing`. Al arrancar, si ese archivo
/// existe, se importa como un dibujo más y se borra el archivo.
struct LegacyDrawingFileImporter {
    static let importedTitle = "Mi primer dibujo"

    private let fileURL: URL
    private let fileManager: FileManager

    init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    static func live(fileManager: FileManager = .default) -> LegacyDrawingFileImporter {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return LegacyDrawingFileImporter(
            fileURL: base.appendingPathComponent("Drawings/current.drawing"),
            fileManager: fileManager
        )
    }

    /// No lanza errores: si la importación falla, el archivo se conserva y se
    /// vuelve a intentar en el siguiente arranque.
    func importIfNeeded(into repository: DrawingRepository, now: Date = Date()) {
        guard fileManager.fileExists(atPath: fileURL.path),
              let strokesData = try? Data(contentsOf: fileURL) else { return }
        let drawing = Drawing(
            id: UUID(),
            title: Self.importedTitle,
            strokesData: strokesData,
            thumbnailData: nil,
            createdAt: now,
            updatedAt: now
        )
        guard (try? repository.save(drawing)) != nil else { return }
        try? fileManager.removeItem(at: fileURL)
    }
}
