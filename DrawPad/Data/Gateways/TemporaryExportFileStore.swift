import Foundation

/// Deja los archivos a compartir en una carpeta temporal de la app.
///
/// La hoja de compartir de iOS necesita un archivo real (con nombre y
/// extensión) para ofrecer "Guardar en Archivos", AirDrop, etc. Antes de cada
/// escritura se vacía la carpeta, para no acumular exportaciones antiguas.
final class TemporaryExportFileStore: ExportFileStore {
    private let directory: URL
    private let fileManager: FileManager

    init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    static func live(fileManager: FileManager = .default) -> TemporaryExportFileStore {
        TemporaryExportFileStore(
            directory: fileManager.temporaryDirectory.appendingPathComponent("Exports", isDirectory: true),
            fileManager: fileManager
        )
    }

    func write(_ data: Data, fileName: String) throws -> URL {
        do {
            try? fileManager.removeItem(at: directory)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent(fileName)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw DrawingError.shareFailed
        }
    }
}
