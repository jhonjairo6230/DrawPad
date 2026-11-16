import Foundation

/// Un portapapeles que siempre tiene lo mismo. Sustituye al del sistema en
/// las pruebas de interfaz (ver ``AppContainer``).
struct FixedClipboard: Clipboard {
    let fixedContent: ClipboardContent?

    init(content: ClipboardContent?) {
        fixedContent = content
    }

    func content() -> ClipboardContent? {
        fixedContent
    }
}
