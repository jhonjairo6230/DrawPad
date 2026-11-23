import PencilKit
import UIKit

/// Implementación de ``DrawingCanvas`` con PencilKit.
///
/// Es el único lugar de la app que conoce `PKCanvasView`, `PKDrawing` y
/// `PKToolPicker`. PencilKit ya resuelve presión, inclinación, borrador y la
/// paleta de herramientas del Apple Pencil (ver docs/adr/0005-pencilkit.md).
@MainActor
final class PencilKitCanvas: NSObject, DrawingCanvas {
    /// La vista que SwiftUI muestra a través de ``PencilCanvasView``. De abajo
    /// arriba: el papel, los textos e imágenes y el lienzo transparente de
    /// PencilKit con los trazos.
    let view: UIView = CanvasContainerView()
    private let paperView = UIView()
    private let elementsLayer = PageElementsLayer()
    private var elements: [PageElement] = []
    /// Tamaño de la hoja en coordenadas de dibujo (ver ``CanvasGeometry``).
    private var pageSize = CGSize.zero
    private let canvasView = PKCanvasView()
    private var background = CanvasBackground.blank
    private var theme = CanvasTheme.light
    /// Una sola paleta para toda la app: así el lápiz y el color elegidos se
    /// mantienen al pasar de una hoja a otra (cada hoja crea su propio lienzo).
    private static let sharedToolPicker = PKToolPicker()
    private var toolPicker: PKToolPicker { Self.sharedToolPicker }

    var onDrawingChanged: (() -> Void)?

    /// Sin trazos (iPhone): no se dibuja, no hay paleta y la hoja empieza
    /// ajustada al ancho de la pantalla. Se puede desplazar y ampliar, y los
    /// elementos (figuras, conexiones, Mermaid) se siguen moviendo en el modo
    /// de mover.
    private let isReadOnly: Bool
    /// Sin trazos, mientras el usuario no amplíe a mano, el zoom se
    /// mantiene ajustado al ancho (la hoja puede cambiar al cargarla o al girar).
    private var userHasZoomed = false

    var onElementMoved: ((UUID, CGRect) -> Void)? {
        get { elementsLayer.onElementMoved }
        set { elementsLayer.onElementMoved = newValue }
    }

    var onElementSelected: ((UUID?) -> Void)? {
        get { elementsLayer.onElementSelected }
        set { elementsLayer.onElementSelected = newValue }
    }

    init(isReadOnly: Bool = false) {
        self.isReadOnly = isReadOnly
        super.init()
        canvasView.delegate = self
        canvasView.drawingPolicy = .pencilOnly
        canvasView.tool = toolPicker.selectedTool
        // Transparente, para que se vea el papel que hay debajo.
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false

        // Zoom con pellizco. El lienzo es un `UIScrollView`: con estos límites
        // ya sabe ampliar y desplazarse (dos dedos, o uno si el dedo no dibuja).
        canvasView.minimumZoomScale = CanvasGeometry.minimumZoom
        canvasView.maximumZoomScale = CanvasGeometry.maximumZoom
        // Sin márgenes automáticos: las cuentas del papel asumen que el
        // contenido empieza en la esquina de la vista.
        canvasView.contentInsetAdjustmentBehavior = .never

        // Lo que asoma al tirar más allá del borde de la hoja.
        view.backgroundColor = .systemGray5
        view.clipsToBounds = true
        view.addSubview(paperView)
        view.addSubview(elementsLayer)
        canvasView.frame = view.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(canvasView)
        (view as? CanvasContainerView)?.onLayout = { [weak self] in
            self?.updatePageSize()
        }
        setBackground(background, theme: theme)
        if isReadOnly {
            // Sin trazos nuevos; el desplazamiento y el zoom siguen funcionando.
            canvasView.drawingGestureRecognizer.isEnabled = false
        }
    }

    /// Muestra la paleta flotante de herramientas. Debe llamarse cuando el
    /// lienzo ya está en una ventana (por eso ``PencilCanvasView`` lo difiere).
    func showToolPicker() {
        guard !isReadOnly else { return }
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    // MARK: - DrawingCanvas

    var isEmpty: Bool { !hasStrokes && elements.isEmpty }

    var hasStrokes: Bool { !canvasView.drawing.strokes.isEmpty }

    var viewportSize: CGSize { canvasView.bounds.size }

    var visibleCenter: CGPoint {
        CanvasGeometry.visibleCenter(
            viewport: canvasView.bounds.size,
            zoomScale: canvasView.zoomScale,
            contentOffset: canvasView.contentOffset
        )
    }

    func showElements(_ elements: [PageElement], selectedID: UUID?) {
        self.elements = elements
        elementsLayer.show(elements, selectedID: selectedID)
        updatePageSize()
    }

    func setArrangingElements(_ enabled: Bool) {
        // El lienzo está encima y se quedaría con todos los toques: mientras
        // se mueven elementos, deja de atenderlos y los recibe la capa.
        canvasView.isUserInteractionEnabled = !enabled
        elementsLayer.isArranging = enabled
    }

    func currentData() -> Data {
        canvasView.drawing.dataRepresentation()
    }

    func load(_ strokesData: Data) throws {
        // Un dibujo recién creado no tiene datos: `PKDrawing(data:)` fallaría.
        canvasView.drawing = strokesData.isEmpty ? PKDrawing() : try PKDrawing(data: strokesData)
        updatePageSize()
    }

    func clear() {
        replaceDrawing(with: PKDrawing())
    }

    func smoothStrokes() {
        guard hasStrokes else { return }
        let smoothed = canvasView.drawing.strokes.map(Self.smoothed)
        replaceDrawing(with: PKDrawing(strokes: smoothed))
    }

    func undo() {
        canvasView.undoManager?.undo()
    }

    func redo() {
        canvasView.undoManager?.redo()
    }

    func setFingerDrawingEnabled(_ enabled: Bool) {
        guard !isReadOnly else { return }
        canvasView.drawingPolicy = enabled ? .anyInput : .pencilOnly
    }

    func setBackground(_ background: CanvasBackground, theme: CanvasTheme) {
        self.background = background
        self.theme = theme
        paperView.backgroundColor = CanvasBackgroundPattern.color(for: background, theme: theme)
        elementsLayer.theme = theme
        // El aspecto del lienzo lo decide el papel, no el modo del sistema:
        // PencilKit adapta la tinta al aspecto (en oscuro, el negro se ve
        // blanco) y la paleta enseña los colores tal como quedarán.
        canvasView.overrideUserInterfaceStyle = interfaceStyle
        toolPicker.colorUserInterfaceStyle = interfaceStyle
    }

    func renderPNG() -> Data? {
        renderImage(scale: canvasView.traitCollection.displayScale, paper: background)?.pngData()
    }

    func setPaperColor(_ color: CoverColor) {
        paperView.backgroundColor = color.uiColor
    }

    func renderStrokesPNG() -> Data? {
        guard hasStrokes else { return nil }
        let rect = renderRect
        guard rect.width > 0, rect.height > 0 else { return nil }
        return strokesImage(in: rect, scale: Self.coverImageScale).pngData()
    }

    func renderPDF() -> Data? {
        guard let rect = nonEmptyRenderRect else { return nil }
        // PencilKit no ofrece los trazos como vectores: el PDF lleva una
        // imagen a alta resolución sobre el papel.
        let strokes = strokesImage(in: rect, scale: Self.pdfImageScale)
        let page = CGRect(origin: .zero, size: rect.size)

        return UIGraphicsPDFRenderer(bounds: page).pdfData { context in
            context.beginPage()
            CanvasBackgroundPattern.color(for: background, theme: theme).setFill()
            context.fill(page)
            PageElementStyle.draw(elements, theme: theme)
            strokes.draw(in: page)
        }
    }

    func renderThumbnail() -> Data? {
        let longestSide = max(pageSize.width, pageSize.height)
        guard longestSide > 0 else { return nil }
        // Como mucho `thumbnailMaxSide` píxeles en el lado más largo.
        return renderImage(scale: min(1, Self.thumbnailMaxSide / longestSide), paper: .blank)?.pngData()
    }

    // MARK: - Renderizado

    private static let thumbnailMaxSide: CGFloat = 480
    private static let pdfImageScale: CGFloat = 3
    /// Resolución de la imagen de una portada dibujada.
    private static let coverImageScale: CGFloat = 2

    private var interfaceStyle: UIUserInterfaceStyle {
        theme == .dark ? .dark : .light
    }

    /// La hoja completa, en coordenadas de dibujo: lo que se exporta no
    /// depende del zoom ni de qué parte se esté viendo.
    private var renderRect: CGRect {
        CGRect(origin: .zero, size: pageSize)
    }

    // MARK: - Suavizado

    /// El mismo trazo (tinta, grosor, presión) con el recorrido suavizado.
    ///
    /// Un trazo de PencilKit es una curva definida por puntos de control;
    /// se suavizan sus posiciones con ``StrokeSmoother`` y se reconstruye.
    private static func smoothed(_ stroke: PKStroke) -> PKStroke {
        let points = Array(stroke.path)
        let locations = StrokeSmoother.smooth(points.map(\.location))
        let controlPoints = zip(points, locations).map { point, location in
            PKStrokePoint(
                location: location,
                timeOffset: point.timeOffset,
                size: point.size,
                opacity: point.opacity,
                force: point.force,
                azimuth: point.azimuth,
                altitude: point.altitude
            )
        }
        return PKStroke(
            ink: stroke.ink,
            path: PKStrokePath(controlPoints: controlPoints, creationDate: stroke.path.creationDate),
            transform: stroke.transform,
            mask: stroke.mask
        )
    }

    /// Cambia el dibujo entero y lo apunta en el historial de deshacer.
    ///
    /// Asignar `drawing` a mano no se puede deshacer por sí solo (PencilKit
    /// solo registra lo que dibuja el usuario). Al deshacer se vuelve a
    /// llamar a este método con el dibujo anterior, y eso registra el rehacer.
    private func replaceDrawing(with newDrawing: PKDrawing) {
        let previous = canvasView.drawing
        canvasView.undoManager?.registerUndo(withTarget: self) { canvas in
            canvas.replaceDrawing(with: previous)
        }
        canvasView.drawing = newDrawing
        updatePageSize()
    }

    // MARK: - Zoom y desplazamiento

    /// Recalcula el tamaño de la hoja (cambió la vista o cambiaron los trazos).
    private func updatePageSize() {
        let viewport = canvasView.bounds.size
        guard viewport.width > 0, viewport.height > 0 else { return }
        let drawing = canvasView.drawing
        pageSize = CanvasGeometry.pageSize(
            viewport: viewport,
            drawingBounds: CanvasGeometry.contentBounds(
                strokes: drawing.strokes.isEmpty ? nil : drawing.bounds,
                elements: elements.map(\.frame)
            )
        )
        if isReadOnly {
            let fit = CanvasGeometry.fitWidthZoom(viewport: viewport, pageSize: pageSize)
            canvasView.minimumZoomScale = fit
            if !userHasZoomed, canvasView.zoomScale != fit {
                canvasView.zoomScale = fit
            }
        }
        let contentSize = CanvasGeometry.contentSize(pageSize: pageSize, zoomScale: canvasView.zoomScale)
        if canvasView.contentSize != contentSize {
            canvasView.contentSize = contentSize
        }
        updatePaperPlacement()
    }

    /// Coloca el papel y la capa de elementos bajo los trazos: mismo zoom y
    /// mismo desplazamiento.
    private func updatePaperPlacement() {
        let zoom = canvasView.zoomScale
        let center = CanvasGeometry.paperCenter(
            pageSize: pageSize,
            zoomScale: zoom,
            contentOffset: canvasView.contentOffset
        )
        for underlay in [paperView, elementsLayer] {
            underlay.bounds = CGRect(origin: .zero, size: pageSize)
            underlay.transform = CGAffineTransform(scaleX: zoom, y: zoom)
            underlay.center = center
        }
    }

    /// El dibujo sobre el papel indicado. `scale` = píxeles por punto.
    private func renderImage(scale: CGFloat, paper: CanvasBackground) -> UIImage? {
        guard let rect = nonEmptyRenderRect else { return nil }
        let strokes = strokesImage(in: rect, scale: scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        return UIGraphicsImageRenderer(bounds: rect, format: format).image { context in
            CanvasBackgroundPattern.color(for: paper, theme: theme).setFill()
            context.fill(rect)
            PageElementStyle.draw(elements, theme: theme)
            strokes.draw(in: rect)
        }
    }

    /// `renderRect` si hay algo que dibujar; `nil` si la hoja está vacía.
    private var nonEmptyRenderRect: CGRect? {
        let rect = renderRect
        guard !isEmpty, rect.width > 0, rect.height > 0 else { return nil }
        return rect
    }

    /// Solo los trazos, sobre transparente.
    ///
    /// `image(from:scale:)` usa el aspecto "actual" para decidir el color de
    /// la tinta: se fija el del papel para que la imagen sea lo que se ve.
    private func strokesImage(in rect: CGRect, scale: CGFloat) -> UIImage {
        let drawing = canvasView.drawing
        var strokes = UIImage()
        UITraitCollection(userInterfaceStyle: interfaceStyle).performAsCurrent {
            strokes = drawing.image(from: rect, scale: scale)
        }
        return strokes
    }
}

extension PencilKitCanvas: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updatePageSize()
        onDrawingChanged?()
    }

    // `PKCanvasViewDelegate` hereda de `UIScrollViewDelegate`: el lienzo avisa
    // de cada desplazamiento y cada cambio de zoom.

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePaperPlacement()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updatePaperPlacement()
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        userHasZoomed = true
    }
}

/// Vista contenedora que avisa cuando cambia de tamaño (primer diseño, giro
/// del iPad, multitarea), para recalcular la hoja.
private final class CanvasContainerView: UIView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}
