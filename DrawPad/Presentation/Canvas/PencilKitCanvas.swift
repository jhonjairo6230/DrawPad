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
    private let toolPicker = PKToolPicker()

    var onDrawingChanged: (() -> Void)?

    override init() {
        super.init()
        canvasView.delegate = self
        canvasView.drawingPolicy = .pencilOnly
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        // Lienzo siempre claro: en modo oscuro PencilKit invierte los colores
        // al mostrarlos y la imagen exportada no coincidiría con lo que se ve.
        canvasView.overrideUserInterfaceStyle = .light
        // Transparente, para que se vea el papel que hay debajo.
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        toolPicker.colorUserInterfaceStyle = .light

        paperView.backgroundColor = CanvasBackgroundPattern.color(for: background)
        for subview in [paperView, canvasView] {
            subview.frame = view.bounds
            subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(subview)
        }
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

    func setBackground(_ background: CanvasBackground) {
        self.background = background
        paperView.backgroundColor = CanvasBackgroundPattern.color(for: background)
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

    /// Área visible del lienzo + cualquier trazo que se salga de ella.
    private var renderRect: CGRect {
        canvasView.bounds.union(canvasView.drawing.bounds)
    }

    /// El dibujo sobre el papel indicado. `scale` = píxeles por punto.
    private func renderImage(scale: CGFloat, paper: CanvasBackground) -> UIImage? {
        let drawing = canvasView.drawing
        let rect = renderRect
        guard !drawing.strokes.isEmpty, rect.width > 0, rect.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        return UIGraphicsImageRenderer(bounds: rect, format: format).image { context in
            CanvasBackgroundPattern.color(for: paper).setFill()
            context.fill(rect)
            drawing.image(from: rect, scale: scale).draw(in: rect)
        }
    }
}

extension PencilKitCanvas: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        onDrawingChanged?()
    }
}
