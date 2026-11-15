import Foundation

/// El papel sobre el que se dibuja.
///
/// El valor `rawValue` es lo que se guarda en la base de datos: no hay que
/// cambiarlo aunque se renombren los casos.
enum CanvasBackground: String, CaseIterable, Equatable {
    case blank
    case grid
    case lines
    case dots
}
