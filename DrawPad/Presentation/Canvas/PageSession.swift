import Foundation

/// Una hoja abierta, vista desde el cuaderno.
///
/// ``NotebookViewModel`` solo necesita poder decirle a la hoja "guarda ya" o
/// "olvida lo pendiente" al cambiar de hoja. Con este protocolo no depende de
/// ``CanvasModule`` (ni, por tanto, de PencilKit) y se puede probar con una
/// sesión falsa.
@MainActor
protocol PageSession: AnyObject {
    /// Guarda ya los cambios pendientes (se va a salir de la hoja).
    func flushPendingSave()
    /// Descarta los cambios pendientes (la hoja se acaba de eliminar).
    func discardPendingSave()
}
