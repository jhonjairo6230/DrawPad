import Foundation

/// Puerto hacia el portapapeles del sistema.
protocol Clipboard {
    /// El texto o la imagen copiados, o `nil` si no hay nada que se pueda pegar.
    func content() -> ClipboardContent?
}
