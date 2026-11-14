import Foundation

/// Todo lo que necesita la pantalla de un dibujo abierto: su ViewModel y su
/// lienzo, creados juntos para que compartan el mismo `PKCanvasView`.
///
/// Es `Hashable` (por identidad) para poder usarlo como destino de navegación:
/// la galería guarda "el módulo abierto" y SwiftUI navega cuando deja de ser `nil`.
@MainActor
final class CanvasModule: Identifiable {
    let viewModel: CanvasViewModel
    let canvas: PencilKitCanvas

    init(viewModel: CanvasViewModel, canvas: PencilKitCanvas) {
        self.viewModel = viewModel
        self.canvas = canvas
    }
}

extension CanvasModule: Hashable {
    nonisolated static func == (lhs: CanvasModule, rhs: CanvasModule) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
