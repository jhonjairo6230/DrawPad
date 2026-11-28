import Foundation

/// Lo que hay en el portapapeles que DrawPad sabe pegar en una hoja.
enum ClipboardContent: Equatable {
    case text(String)
    /// - Parameter size: tamaño de la imagen en puntos.
    case image(data: Data, size: CGSize)
}
