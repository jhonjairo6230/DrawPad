import Foundation
@testable import DrawPad

/// Biblioteca falsa: recuerda lo que se le pidió añadir y puede simular fallos.
final class SpyImageLibrary: ImageLibrary {
    private(set) var added: [Data] = []
    var error: DrawingError?

    func addPNG(_ pngData: Data) async throws {
        if let error { throw error }
        added.append(pngData)
    }
}
