import PencilKit
import UIKit

/// Implementación de ``DrawingCanvas`` con PencilKit.
///
/// Es el único lugar de la app que conoce `PKCanvasView`, `PKDrawing` y
/// `PKToolPicker`. PencilKit ya resuelve presión, inclinación, borrador y la
/// paleta de herramientas del Apple Pencil (ver docs/adr/0005-pencilkit.md).
@MainActor
final class PencilKitCanvas: NSObject, DrawingCanvas {
    /// La vista que SwiftUI muestra a través de ``PencilCanvasView``: el papel
    /// de fondo y, encima, el lienzo transparente de PencilKit.
    let view: UIView = CanvasContainerView()
    private let paperView = UIView()
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

    override init() {
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
        canvasView.frame = view.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(canvasView)
        (view as? CanvasContainerView)?.onLayout = { [weak self] in
            self?.updatePageSize()
        }
        setBackground(background, theme: theme)
    }

    /// Muestra la paleta flotante de herramientas. Debe llamarse cuando el
    /// lienzo ya está en una ventana (por eso ``PencilCanvasView`` lo difiere).
    func showToolPicker() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    // MARK: - DrawingCanvas

    var isEmpty: Bool { canvasView.drawing.strokes.isEmpty }

    func currentData() -> Data {
        canvasView.drawing.dataRepresentation()
    }

    func load(_ strokesData: Data) throws {
        // Un dibujo recién creado no tiene datos: `PKDrawing(data:)` fallaría.
        canvasView.drawing = strokesData.isEmpty ? PKDrawing() : try PKDrawing(data: strokesData)
        updatePageSize()
    }

    func clear() {
        canvasView.drawing = PKDrawing()
        updatePageSize()
    }

    func undo() {
        canvasView.undoManager?.undo()
    }

    func redo() {
        canvasView.undoManager?.redo()
    }

    func setFingerDrawingEnabled(_ enabled: Bool) {
        canvasView.drawingPolicy = enabled ? .anyInput : .pencilOnly
    }

    func setBackground(_ background: CanvasBackground, theme: CanvasTheme) {
        self.background = background
        self.theme = theme
        paperView.backgroundColor = CanvasBackgroundPattern.color(for: background, theme: theme)
        // El aspecto del lienzo lo decide el papel, no el modo del sistema:
        // PencilKit adapta la tinta al aspecto (en oscuro, el negro se ve
        // blanco) y la paleta enseña los colores tal como quedarán.
        canvasView.overrideUserInterfaceStyle = interfaceStyle
        toolPicker.colorUserInterfaceStyle = interfaceStyle
    }

    func renderPNG() -> Data? {
        renderImage(scale: canvasView.traitCollection.displayScale, paper: background)?.pngData()
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

    private var interfaceStyle: UIUserInterfaceStyle {
        theme == .dark ? .dark : .light
    }

    /// La hoja completa, en coordenadas de dibujo: lo que se exporta no
    /// depende del zoom ni de qué parte se esté viendo.
    private var renderRect: CGRect {
        CGRect(origin: .zero, size: pageSize)
    }

    // MARK: - Zoom y desplazamiento

    /// Recalcula el tamaño de la hoja (cambió la vista o cambiaron los trazos).
    private func updatePageSize() {
        let viewport = canvasView.bounds.size
        guard viewport.width > 0, viewport.height > 0 else { return }
        let drawing = canvasView.drawing
        pageSize = CanvasGeometry.pageSize(
            viewport: viewport,
            drawingBounds: drawing.strokes.isEmpty ? nil : drawing.bounds
        )
        let contentSize = CanvasGeometry.contentSize(pageSize: pageSize, zoomScale: canvasView.zoomScale)
        if canvasView.contentSize != contentSize {
            canvasView.contentSize = contentSize
        }
        updatePaperPlacement()
    }

    /// Coloca el papel bajo los trazos: mismo zoom y mismo desplazamiento.
    private func updatePaperPlacement() {
        let zoom = canvasView.zoomScale
        paperView.bounds = CGRect(origin: .zero, size: pageSize)
        paperView.transform = CGAffineTransform(scaleX: zoom, y: zoom)
        paperView.center = CanvasGeometry.paperCenter(
            pageSize: pageSize,
            zoomScale: zoom,
            contentOffset: canvasView.contentOffset
        )
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
            strokes.draw(in: rect)
        }
    }

    /// `renderRect` si hay algo que dibujar; `nil` si el lienzo está vacío.
    private var nonEmptyRenderRect: CGRect? {
        let rect = renderRect
        guard !canvasView.drawing.strokes.isEmpty, rect.width > 0, rect.height > 0 else { return nil }
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
