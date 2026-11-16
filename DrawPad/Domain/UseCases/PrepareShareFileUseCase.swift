import Foundation

/// Prepara el archivo que se va a compartir: le pone un nombre válido a
/// partir del título del dibujo y lo deja en un lugar legible por otras apps.
struct PrepareShareFileUseCase {
    private let store: ExportFileStore

    init(store: ExportFileStore) {
        self.store = store
    }

    /// - Parameter data: el dibujo ya convertido al formato por la presentación.
    /// - Throws: ``DrawingError/emptyDrawing`` si no hay datos, o
    ///   ``DrawingError/shareFailed`` si no se pudo escribir el archivo.
    func execute(title: String, format: ExportFormat, data: Data) throws -> URL {
        guard !data.isEmpty else { throw DrawingError.emptyDrawing }
        let fileName = "\(Self.safeFileName(from: title)).\(format.fileExtension)"
        return try store.write(data, fileName: fileName)
    }

    /// Quita del título lo que no puede ir en un nombre de archivo.
    /// "Plano: casa/jardín" → "Plano- casa-jardín". Vacío → "Dibujo".
    static func safeFileName(from title: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/\\:*?\"<>|").union(.newlines).union(.controlCharacters)
        let cleaned = title
            .components(separatedBy: forbidden)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ".")))
        return cleaned.isEmpty ? "Dibujo" : cleaned
    }
}
