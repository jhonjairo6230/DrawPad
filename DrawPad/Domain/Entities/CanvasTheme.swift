import Foundation

/// Color del papel: claro (blanco) u oscuro (casi negro).
///
/// Es independiente del patrón (``CanvasBackground``): cualquier papel puede
/// ser claro u oscuro. El `rawValue` es lo que se guarda en la base de datos.
enum CanvasTheme: String, CaseIterable, Equatable {
    case light
    case dark
}
