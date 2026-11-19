import Foundation

/// Cómo se muestra cada figura en el menú "Insertar". Vive en Presentation
/// porque los nombres y los iconos son asunto de la interfaz.
extension ShapeKind {
    var title: String {
        switch self {
        case .rectangle: return "Cuadrado"
        case .ellipse: return "Círculo"
        case .diamond: return "Rombo"
        case .cylinder: return "Cilindro"
        }
    }

    /// Nombre de un símbolo de SF Symbols.
    var symbolName: String {
        switch self {
        case .rectangle: return "square"
        case .ellipse: return "circle"
        case .diamond: return "diamond"
        case .cylinder: return "cylinder"
        }
    }
}
