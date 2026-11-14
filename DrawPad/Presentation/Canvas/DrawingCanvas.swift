import Foundation

/// Lo que el ViewModel necesita de un lienzo de dibujo.
///
/// Es un *puerto* de la capa de presentación: el ViewModel habla con este
/// protocolo y no con `PKCanvasView`. Así se puede probar con un lienzo falso
/// (`FakeDrawingCanvas` en las pruebas) sin PencilKit ni pantalla.
@MainActor
protocol DrawingCanvas: AnyObject {
    /// Se llama cada vez que cambian los trazos (dibujar, borrar, deshacer…).
    var onDrawingChanged: (() -> Void)? { get set }
    /// `true` si no hay ningún trazo.
    var isEmpty: Bool { get }

    /// Trazos actuales serializados (ver ``Drawing/strokesData``).
    func currentData() -> Data
    /// Reemplaza el contenido del lienzo por unos trazos guardados.
    func load(_ strokesData: Data) throws
    func clear()
    func undo()
    func redo()
    /// `false`: solo dibuja el Apple Pencil (el dedo no deja trazo).
    func setFingerDrawingEnabled(_ enabled: Bool)
    /// El dibujo como PNG con fondo blanco, o `nil` si está vacío.
    func renderPNG() -> Data?
}
