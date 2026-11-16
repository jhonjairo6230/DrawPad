import Foundation

/// Cómo se muestra cada papel en el menú. Vive en Presentation porque los
/// textos y los iconos son asunto de la interfaz, no del dominio.
extension CanvasBackground {
    var title: String {
        switch self {
        case .blank: return "Blanco"
        case .grid: return "Cuadrícula"
        case .lines: return "Líneas"
        case .dots: return "Puntos"
        }
    }

    /// Nombre de un símbolo de SF Symbols.
    var symbolName: String {
        switch self {
        case .blank: return "rectangle"
        case .grid: return "squareshape.split.3x3"
        case .lines: return "line.3.horizontal"
        case .dots: return "circle.grid.3x3"
        }
    }
}
