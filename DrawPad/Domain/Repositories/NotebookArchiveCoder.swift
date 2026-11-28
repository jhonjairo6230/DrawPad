import Foundation

/// Puerto para convertir un cuaderno completo en un archivo y al revés.
protocol NotebookArchiveCoder {
    /// Extensión del archivo, sin punto ("drawpad").
    var fileExtension: String { get }

    /// - Throws: ``DrawingError/exportFailed`` si no se pudo escribir.
    func encode(_ bundle: NotebookBundle) throws -> Data

    /// - Throws: ``DrawingError/importFailed`` si no es un cuaderno válido, o
    ///   ``DrawingError/unsupportedArchiveVersion`` si es de una versión de la
    ///   app más nueva.
    func decode(_ data: Data) throws -> NotebookBundle
}
