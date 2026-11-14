import Foundation

/// Errores de negocio que la interfaz sabe mostrar al usuario.
///
/// Las capas externas (Data) traducen sus errores técnicos a estos casos, para
/// que la presentación nunca dependa de errores de `FileManager` o `Photos`.
enum DrawingError: Error, Equatable {
    /// No se pudo leer o escribir el dibujo en el almacenamiento local.
    case storageFailed
    /// El usuario no dio permiso para añadir imágenes a Fotos.
    case photoLibraryAccessDenied
    /// Fotos rechazó la imagen.
    case exportFailed
    /// Se intentó exportar un dibujo sin trazos.
    case emptyDrawing
}

extension DrawingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .storageFailed:
            return "No se pudo guardar o recuperar tu dibujo."
        case .photoLibraryAccessDenied:
            return "DrawPad no tiene permiso para guardar en Fotos. Actívalo en Ajustes > DrawPad > Fotos."
        case .exportFailed:
            return "No se pudo guardar la imagen en Fotos."
        case .emptyDrawing:
            return "El lienzo está vacío: dibuja algo antes de exportar."
        }
    }
}
