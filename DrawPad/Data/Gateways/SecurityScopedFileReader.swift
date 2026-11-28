import Foundation

/// Lee un archivo que el usuario eligió fuera de la app (Archivos, iCloud
/// Drive) o con el que abrió la app.
///
/// Un archivo de fuera del contenedor de la app solo se puede leer pidiendo
/// acceso temporal (`startAccessingSecurityScopedResource`). Si el archivo ya
/// es de la app (iOS lo copió al abrirlo desde otra app), pedirlo no hace
/// falta pero tampoco molesta.
struct SecurityScopedFileReader: ImportedFileReader {
    func read(_ url: URL) throws -> Data {
        let granted = url.startAccessingSecurityScopedResource()
        defer {
            if granted { url.stopAccessingSecurityScopedResource() }
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw DrawingError.importFailed
        }
    }
}
