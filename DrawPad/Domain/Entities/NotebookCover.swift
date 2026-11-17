import Foundation

/// La tapa de un cuaderno: un color y un estilo. No es una hoja ni un dibujo;
/// la interfaz la pinta a partir de estos dos valores y del título.
///
/// Los `rawValue` son lo que se guarda en la base de datos: no hay que
/// cambiarlos aunque se renombren los casos.
struct NotebookCover: Equatable {
    var color: CoverColor
    var style: CoverStyle

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
}
