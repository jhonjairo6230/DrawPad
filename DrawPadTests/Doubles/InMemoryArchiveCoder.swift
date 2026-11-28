import Foundation
@testable import DrawPad

/// Formato falso: recuerda los cuadernos que se le pidió escribir y, al leer,
/// devuelve lo que la prueba diga.
final class InMemoryArchiveCoder: NotebookArchiveCoder {
    let fileExtension = "drawpad"
    private(set) var encoded: [NotebookBundle] = []
    var decodeResult: Result<NotebookBundle, DrawingError> = .failure(.importFailed)

    func encode(_ bundle: NotebookBundle) throws -> Data {
        encoded.append(bundle)
        return Data("archivo".utf8)
    }

    func decode(_ data: Data) throws -> NotebookBundle {
        try decodeResult.get()
    }
}

/// Lector falso: devuelve siempre los mismos datos o falla.
final class FakeFileReader: ImportedFileReader {
    var data = Data("archivo".utf8)
    var error: DrawingError?
    private(set) var readURLs: [URL] = []

    func read(_ url: URL) throws -> Data {
        readURLs.append(url)
        if let error { throw error }
        return data
    }
}
