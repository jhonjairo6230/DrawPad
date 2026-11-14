import PencilKit
import SwiftUI

/// Puente entre SwiftUI y UIKit: muestra el `PKCanvasView` de ``PencilKitCanvas``.
///
/// `UIViewRepresentable` es la forma oficial de usar una vista de UIKit dentro
/// de SwiftUI. Aquí no hay lógica: solo se entrega la vista ya configurada.
struct PencilCanvasView: UIViewRepresentable {
    let canvas: PencilKitCanvas

    func makeUIView(context: Context) -> PKCanvasView {
        // La paleta necesita que el lienzo esté en una ventana, y eso ocurre
        // justo después de `makeUIView`: se difiere al siguiente ciclo.
        DispatchQueue.main.async { [canvas] in
            canvas.showToolPicker()
        }
        return canvas.canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
