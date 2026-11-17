import Foundation
@testable import DrawPad

/// Portapapeles falso: las pruebas deciden qué hay copiado.
final class FakeClipboard: Clipboard {
    var current: ClipboardContent?

    init(_ current: ClipboardContent? = nil) {
        self.current = current
    }

    func content() -> ClipboardContent? {
        current
    }
}
