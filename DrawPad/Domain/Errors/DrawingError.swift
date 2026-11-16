import Foundation

/// Errores de negocio que la interfaz sabe mostrar al usuario.
///
/// Las capas externas (Data) traducen sus errores técnicos a estos casos, para
/// que la presentación nunca dependa de errores de SwiftData o `Photos`.
enum DrawingError: Error, Equatable {
    /// No se pudo leer o escribir en la base de datos local.
    case storageFailed
    /// La hoja ya no existe (por ejemplo, se eliminó).
    case drawingNotFound
    /// El cuaderno ya no existe.
    case notebookNotFound
    /// Se intentó eliminar la única hoja de un cuaderno.
    case lastPage
    /// El título está vacío.
    case invalidTitle
    /// El usuario no dio permiso para añadir imágenes a Fotos.
    case photoLibraryAccessDenied
    /// Fotos rechazó la imagen.
    case exportFailed
    /// No se pudo preparar el archivo para compartir.
    case shareFailed
    /// Se intentó guardar un cuadro de texto vacío.
    case emptyText
    /// No hay texto ni imágenes en el portapapeles.
    case clipboardEmpty
    /// El texto o la imagen ya no existe en la hoja.
    case elementNotFound
    /// Se intentó exportar una hoja sin trazos.
    case emptyDrawing
}

extension DrawingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .storageFailed:
            return "No se pudo guardar o recuperar tus cuadernos."
        case .drawingNotFound:
            return "Esa hoja ya no existe."
        case .notebookNotFound:
            return "Ese cuaderno ya no existe."
        case .lastPage:
            return "Un cuaderno necesita al menos una hoja."
        case .invalidTitle:
            return "El título no puede estar vacío."
        case .photoLibraryAccessDenied:
            return "DrawPad no tiene permiso para guardar en Fotos. Actívalo en Ajustes > DrawPad > Fotos."
        case .exportFailed:
            return "No se pudo guardar la imagen en Fotos."
        case .shareFailed:
            return "No se pudo preparar el archivo para compartir."
        case .emptyText:
            return "Escribe algo antes de guardar."
        case .clipboardEmpty:
            return "No hay texto ni imágenes en el portapapeles. Copia algo primero."
        case .elementNotFound:
            return "Ese elemento ya no está en la hoja."
        case .emptyDrawing:
            return "La hoja está vacía: dibuja algo antes de exportar o compartir."
        }
    }
}
