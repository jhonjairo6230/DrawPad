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
    let view = UIView()
    private let paperView = UIView()
    private let canvasView = PKCanvasView()
    private var background = CanvasBackground.blank
    private var theme = CanvasTheme.light
    private let toolPicker = PKToolPicker()

    var onDrawingChanged: (() -> Void)?

    override init() {
        super.init()
        canvasView.delegate = self
        canvasView.drawingPolicy = .pencilOnly
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        // Transparente, para que se vea el papel que hay debajo.
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false

        for subview in [paperView, canvasView] {
            subview.frame = view.bounds
            subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(subview)
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
    }

    func clear() {
        canvasView.drawing = PKDrawing()
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

    func renderThumbnail() -> Data? {
        let longestSide = max(renderRect.width, renderRect.height)
        guard longestSide > 0 else { return nil }
        // Como mucho `thumbnailMaxSide` píxeles en el lado más largo.
        return renderImage(scale: min(1, Self.thumbnailMaxSide / longestSide), paper: .blank)?.pngData()
    }

    // MARK: - Renderizado

    private static let thumbnailMaxSide: CGFloat = 480

    private var interfaceStyle: UIUserInterfaceStyle {
        theme == .dark ? .dark : .light
    }

    /// Área visible del lienzo + cualquier trazo que se salga de ella.
    private var renderRect: CGRect {
        canvasView.bounds.union(canvasView.drawing.bounds)
    }

    /// El dibujo sobre el papel indicado. `scale` = píxeles por punto.
    private func renderImage(scale: CGFloat, paper: CanvasBackground) -> UIImage? {
        let drawing = canvasView.drawing
        let rect = renderRect
        guard !drawing.strokes.isEmpty, rect.width > 0, rect.height > 0 else { return nil }

        // `image(from:scale:)` usa el aspecto "actual" para decidir el color de
        // la tinta: se fija el del papel para que la imagen sea lo que se ve.
        var strokes = UIImage()
        UITraitCollection(userInterfaceStyle: interfaceStyle).performAsCurrent {
            strokes = drawing.image(from: rect, scale: scale)
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        return UIGraphicsImageRenderer(bounds: rect, format: format).image { context in
            CanvasBackgroundPattern.color(for: paper, theme: theme).setFill()
            context.fill(rect)
            strokes.draw(in: rect)
        }
    }
}

extension PencilKitCanvas: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        onDrawingChanged?()
    }
}
