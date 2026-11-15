import Foundation
import Observation

/// Ajustes del lienzo que se mantienen al pasar de una hoja a otra.
///
/// Cada hoja abierta tiene su propio ``CanvasViewModel``; lo que debe
/// sobrevivir al cambio de hoja vive aquí, en un objeto compartido que crea
/// ``AppContainer``. Solo dura mientras la app está abierta.
@MainActor
@Observable
final class CanvasPreferences {
    /// `false`: solo dibuja el Apple Pencil.
    var isFingerDrawingEnabled = false
}
