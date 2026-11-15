import UIKit
import SwiftUI

/// Puente entre SwiftUI y UIKit: muestra la vista de ``PencilKitCanvas``.
///
/// `UIViewRepresentable` es la forma oficial de usar una vista de UIKit dentro
/// de SwiftUI. Aquí no hay lógica: solo se entrega la vista ya configurada.
struct PencilCanvasView: UIViewRepresentable {
    let canvas: PencilKitCanvas

    func makeUIView(context: Context) -> UIView {
        // La paleta necesita que el lienzo esté en una ventana, y eso ocurre
        // justo después de `makeUIView`: se difiere al siguiente ciclo.
        DispatchQueue.main.async { [canvas] in
            canvas.showToolPicker()
        }
        return canvas.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
