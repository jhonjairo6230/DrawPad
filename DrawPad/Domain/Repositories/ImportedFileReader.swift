import Foundation

/// Puerto para leer un archivo elegido por el usuario (en Archivos, iCloud
/// Drive o abierto desde otra app).
protocol ImportedFileReader {
    /// - Throws: ``DrawingError/importFailed`` si no se puede leer.
    func read(_ url: URL) throws -> Data
}
