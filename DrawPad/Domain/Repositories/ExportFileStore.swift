import Foundation

/// Puerto para dejar un archivo donde otras apps puedan leerlo (compartir).
protocol ExportFileStore {
    /// Escribe el archivo y devuelve dónde quedó.
    /// - Throws: ``DrawingError/shareFailed``.
    func write(_ data: Data, fileName: String) throws -> URL
}
