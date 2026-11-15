import SwiftUI
import UIKit

/// La hoja de compartir de iOS (AirDrop, Archivos, Mensajes, Imprimir…).
///
/// SwiftUI tiene `ShareLink`, pero exige tener el archivo preparado antes de
/// pintar el botón. Aquí el archivo se genera cuando el usuario elige el
/// formato, así que se usa `UIActivityViewController` directamente.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
