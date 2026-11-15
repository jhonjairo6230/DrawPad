import Foundation

/// Errores de negocio que la interfaz sabe mostrar al usuario.
///
/// Las capas externas (Data) traducen sus errores técnicos a estos casos, para
/// que la presentación nunca dependa de errores de SwiftData o `Photos`.
enum DrawingError: Error, Equatable {
    /// No se pudo leer o escribir en la base de datos local.
    case storageFailed
    /// El dibujo ya no existe (por ejemplo, se eliminó).
    case drawingNotFound
    /// El título está vacío.
    case invalidTitle
    /// El usuario no dio permiso para añadir imágenes a Fotos.
    case photoLibraryAccessDenied
    /// Fotos rechazó la imagen.
    case exportFailed
    /// No se pudo preparar el archivo para compartir.
    case shareFailed
    /// Se intentó exportar un dibujo sin trazos.
    case emptyDrawing
}

extension DrawingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .storageFailed:
            return "No se pudo guardar o recuperar tus dibujos."
        case .drawingNotFound:
            return "Ese dibujo ya no existe."
        case .invalidTitle:
            return "El título no puede estar vacío."
        case .photoLibraryAccessDenied:
            return "DrawPad no tiene permiso para guardar en Fotos. Actívalo en Ajustes > DrawPad > Fotos."
        case .exportFailed:
            return "No se pudo guardar la imagen en Fotos."
        case .shareFailed:
            return "No se pudo preparar el archivo para compartir."
        case .emptyDrawing:
            return "El lienzo está vacío: dibuja algo antes de exportar o compartir."
        }
    }
}
