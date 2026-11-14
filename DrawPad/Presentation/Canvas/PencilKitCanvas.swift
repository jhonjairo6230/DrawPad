import PencilKit
import UIKit

/// Implementación de ``DrawingCanvas`` con PencilKit.
///
/// Es el único lugar de la app que conoce `PKCanvasView`, `PKDrawing` y
/// `PKToolPicker`. PencilKit ya resuelve presión, inclinación, borrador y la
/// paleta de herramientas del Apple Pencil (ver docs/adr/0005-pencilkit.md).
@MainActor
final class PencilKitCanvas: NSObject, DrawingCanvas {
    /// La vista que SwiftUI muestra a través de ``PencilCanvasView``.
    let canvasView = PKCanvasView()
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
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        toolPicker.colorUserInterfaceStyle = .light
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
        canvasView.drawing = try PKDrawing(data: strokesData)
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

    func renderPNG() -> Data? {
        let drawing = canvasView.drawing
        guard !drawing.strokes.isEmpty else { return nil }

        // Área visible del lienzo + cualquier trazo que se salga de ella.
        let rect = canvasView.bounds.union(drawing.bounds)
        let format = UIGraphicsImageRendererFormat()
        format.scale = canvasView.traitCollection.displayScale
        format.opaque = true

        let image = UIGraphicsImageRenderer(bounds: rect, format: format).image { context in
            UIColor.white.setFill()
            context.fill(rect)
            drawing.image(from: rect, scale: format.scale).draw(in: rect)
        }
        return image.pngData()
    }
}

extension PencilKitCanvas: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        onDrawingChanged?()
    }
}
