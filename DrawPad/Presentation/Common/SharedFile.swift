import Foundation

/// Un archivo listo para la hoja de compartir. Es `Identifiable` para poder
/// presentarla con `.sheet(item:)`.
struct SharedFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}
