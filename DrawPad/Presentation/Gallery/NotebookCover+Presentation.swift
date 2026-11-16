import SwiftUI

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
    var color: Color {
        switch self {
        case .blue: return Color(red: 0.15, green: 0.39, blue: 0.92)
        case .teal: return Color(red: 0.05, green: 0.58, blue: 0.53)
        case .green: return Color(red: 0.09, green: 0.64, blue: 0.29)
        case .yellow: return Color(red: 0.79, green: 0.54, blue: 0.02)
        case .orange: return Color(red: 0.92, green: 0.35, blue: 0.05)
        case .red: return Color(red: 0.86, green: 0.15, blue: 0.15)
        case .purple: return Color(red: 0.49, green: 0.23, blue: 0.93)
        case .graphite: return Color(red: 0.22, green: 0.25, blue: 0.32)
        }
    }
}

extension CoverStyle {
    var title: String {
        switch self {
        case .plain: return "Lisa"
        case .label: return "Etiqueta"
        case .spine: return "Lomo"
        }
    }
}
