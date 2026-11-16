import Foundation
@testable import DrawPad

/// Almacén falso: recuerda lo que se le pidió escribir y puede simular fallos.
final class SpyExportFileStore: ExportFileStore {
    private(set) var written: [(data: Data, fileName: String)] = []
    var error: DrawingError?

    func write(_ data: Data, fileName: String) throws -> URL {
        if let error { throw error }
        written.append((data, fileName))
        return URL(fileURLWithPath: "/tmp/\(fileName)")
    }
}
