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
    /// Unos datos vacíos dejan el lienzo en blanco.
    func load(_ strokesData: Data) throws
    func clear()
    func undo()
    func redo()
    /// `false`: solo dibuja el Apple Pencil (el dedo no deja trazo).
    func setFingerDrawingEnabled(_ enabled: Bool)
    /// Cambia el papel: su patrón y si es claro u oscuro. No modifica los
    /// trazos, aunque en papel oscuro la tinta negra se muestra blanca.
    func setBackground(_ background: CanvasBackground, theme: CanvasTheme)
    /// El dibujo como PNG sobre su papel de fondo, o `nil` si está vacío.
    func renderPNG() -> Data?
    /// Versión pequeña del dibujo para la galería, sobre papel liso (el
    /// patrón en pequeño ensucia la miniatura); `nil` si está vacío.
    func renderThumbnail() -> Data?
}
