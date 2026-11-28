import SwiftUI
import UIKit

/// Cómo se muestran los colores y estilos de tapa. Vive en Presentation
/// porque los nombres y los colores exactos son asunto de la interfaz.
extension CoverColor {
    var title: String {
        switch self {
        case .blue: return "Azul"
        case .teal: return "Turquesa"
        case .green: return "Verde"
        case .yellow: return "Amarillo"
        case .orange: return "Naranja"
        case .red: return "Rojo"
        case .purple: return "Morado"
        case .graphite: return "Grafito"
        }
    }

    /// Tonos fijos (no los del sistema): la tapa es "cartón", y debe verse
    /// igual en modo claro y oscuro, con el título en blanco legible encima.
    ///
    /// Es un `UIColor` porque también lo usa el lienzo de UIKit al dibujar la
    /// portada; SwiftUI usa ``color``.
    var uiColor: UIColor {
        switch self {
        case .blue: return UIColor(red: 0.15, green: 0.39, blue: 0.92, alpha: 1)
        case .teal: return UIColor(red: 0.05, green: 0.58, blue: 0.53, alpha: 1)
        case .green: return UIColor(red: 0.09, green: 0.64, blue: 0.29, alpha: 1)
        case .yellow: return UIColor(red: 0.79, green: 0.54, blue: 0.02, alpha: 1)
        case .orange: return UIColor(red: 0.92, green: 0.35, blue: 0.05, alpha: 1)
        case .red: return UIColor(red: 0.86, green: 0.15, blue: 0.15, alpha: 1)
        case .purple: return UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1)
        case .graphite: return UIColor(red: 0.22, green: 0.25, blue: 0.32, alpha: 1)
        }
    }

    var color: Color { Color(uiColor: uiColor) }
}

extension CoverStyle {
    var title: String {
        switch self {
        case .plain: return "Lisa"
        case .label: return "Etiqueta"
        case .spine: return "Lomo"
        case .drawn: return "Dibujo"
        }
    }
}
