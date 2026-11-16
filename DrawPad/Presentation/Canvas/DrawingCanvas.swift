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
    /// El usuario movió o cambió de tamaño un texto o una imagen.
    var onElementMoved: ((UUID, CGRect) -> Void)? { get set }
    /// El usuario tocó un texto o una imagen (o el fondo: `nil`).
    var onElementSelected: ((UUID?) -> Void)? { get set }
    /// `true` si la hoja no tiene trazos, textos ni imágenes.
    var isEmpty: Bool { get }
    /// `true` si hay al menos un trazo.
    var hasStrokes: Bool { get }
    /// El punto de la hoja que se ve en el centro de la pantalla.
    var visibleCenter: CGPoint { get }
    /// Tamaño de la parte de la hoja que cabe en pantalla sin zoom.
    var viewportSize: CGSize { get }

    /// Trazos actuales serializados (ver ``Drawing/strokesData``).
    func currentData() -> Data
    /// Reemplaza el contenido del lienzo por unos trazos guardados.
    /// Unos datos vacíos dejan el lienzo en blanco.
    func load(_ strokesData: Data) throws
    /// Borra todos los trazos. Se puede deshacer.
    func clear()
    func undo()
    func redo()
    /// Reduce el temblor de todos los trazos. Se puede deshacer.
    func smoothStrokes()
    /// `false`: solo dibuja el Apple Pencil (el dedo no deja trazo).
    func setFingerDrawingEnabled(_ enabled: Bool)
    /// Muestra estos textos e imágenes bajo los trazos, marcando el seleccionado.
    func showElements(_ elements: [PageElement], selectedID: UUID?)
    /// `true`: los toques mueven textos e imágenes y no se puede dibujar,
    /// ampliar ni desplazar. `false`: el lienzo funciona como siempre.
    func setArrangingElements(_ enabled: Bool)
    /// Cambia el papel: su patrón y si es claro u oscuro. No modifica los
    /// trazos, aunque en papel oscuro la tinta negra se muestra blanca.
    func setBackground(_ background: CanvasBackground, theme: CanvasTheme)
    /// La hoja como PNG (papel, textos, imágenes y trazos), o `nil` si está vacía.
    func renderPNG() -> Data?
    /// La hoja como PDF de una página, o `nil` si está vacía.
    func renderPDF() -> Data?
    /// Versión pequeña de la hoja, sobre papel liso (el patrón en pequeño
    /// ensucia la miniatura); `nil` si está vacía.
    func renderThumbnail() -> Data?
}
