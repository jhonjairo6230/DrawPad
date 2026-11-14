import Foundation

/// Exporta el dibujo como imagen a la biblioteca de Fotos.
struct ExportDrawingUseCase {
    private let library: ImageLibrary

    init(library: ImageLibrary) {
        self.library = library
    }

    /// - Parameter pngData: el dibujo ya convertido a PNG por la presentación.
    /// - Throws: ``DrawingError/emptyDrawing`` si no hay imagen, o el error de la biblioteca.
    func execute(pngData: Data) async throws {
        guard !pngData.isEmpty else { throw DrawingError.emptyDrawing }
        try await library.addPNG(pngData)
    }
}
