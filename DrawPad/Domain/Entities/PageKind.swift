import Foundation

/// Qué es una hoja del cuaderno.
///
/// El `rawValue` es lo que se guarda en la base de datos y en los archivos
/// `.drawpad`: no se cambia aunque se renombren los casos.
enum PageKind: String, CaseIterable, Equatable {
    /// Lienzo para dibujar con el Pencil, con textos, imágenes y figuras.
    case drawing
    /// Documento en Markdown (un spec, una documentación), escrito con el
    /// teclado y leído formateado.
    case markdown
}
