import Foundation

/// Formatos en los que se puede compartir un dibujo.
enum ExportFormat: String, CaseIterable, Equatable {
    case png
    case pdf

    var fileExtension: String { rawValue }
}
