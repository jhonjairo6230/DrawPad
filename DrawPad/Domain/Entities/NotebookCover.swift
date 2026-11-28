import Foundation

/// La tapa de un cuaderno: un color y un estilo. No es una hoja ni un dibujo;
/// la interfaz la pinta a partir de estos dos valores y del título.
///
/// Los `rawValue` son lo que se guarda en la base de datos: no hay que
/// cambiarlos aunque se renombren los casos.
struct NotebookCover: Equatable {
    var color: CoverColor
    var style: CoverStyle
    /// Dibujo hecho a mano para la tapa. Se muestra con el estilo
    /// ``CoverStyle/drawn``; se conserva aunque se cambie a otro estilo, para
    /// no perderlo al probar.
    var drawing: CoverDrawing? = nil

    /// La tapa de los cuadernos que no han elegido ninguna.
    static let standard = NotebookCover(color: .blue, style: .label)
}

enum CoverColor: String, CaseIterable, Equatable {
    case blue
    case teal
    case green
    case yellow
    case orange
    case red
    case purple
    case graphite
}

enum CoverStyle: String, CaseIterable, Equatable {
    /// Solo el color, con el título encima.
    case plain
    /// Una etiqueta blanca con el título, como en los cuadernos escolares.
    case label
    /// Una franja oscura a la izquierda, como el lomo de un cuaderno cosido.
    case spine
    /// El dibujo de ``NotebookCover/drawing`` sobre el color, con el título
    /// en una franja abajo.
    case drawn
}

/// Un dibujo hecho a mano para la tapa de un cuaderno.
///
/// Se guarda dos veces: los trazos, para poder seguir editándolo, y una
/// imagen ya hecha, para que la galería lo muestre sin abrir PencilKit. La
/// imagen tiene fondo transparente: el color de la tapa se ve debajo y se
/// puede cambiar sin volver a dibujar.
struct CoverDrawing: Equatable {
    /// Trazos serializados (`PKDrawing`), opacos para el dominio.
    let strokesData: Data
    /// PNG con fondo transparente, en la proporción de la tapa (3:4).
    let imageData: Data
}
