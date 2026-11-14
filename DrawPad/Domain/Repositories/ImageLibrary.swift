import Foundation

/// Puerto hacia una biblioteca de imágenes externa (la app Fotos).
protocol ImageLibrary {
    /// Añade una imagen PNG a la biblioteca.
    /// - Throws: ``DrawingError/photoLibraryAccessDenied`` o ``DrawingError/exportFailed``.
    func addPNG(_ pngData: Data) async throws
}
