import Foundation
@testable import DrawPad

/// Lienzo falso: sustituye a PencilKit en las pruebas del ViewModel.
@MainActor
final class FakeDrawingCanvas: DrawingCanvas {
    var onDrawingChanged: (() -> Void)?
    var onElementMoved: ((UUID, CGRect) -> Void)?
    var onElementSelected: ((UUID?) -> Void)?
    var visibleCenter = CGPoint(x: 400, y: 300)
    var viewportSize = CGSize(width: 800, height: 600)
    private(set) var shownElements: [PageElement] = []
    private(set) var shownSelectedID: UUID?
    private(set) var isArrangingElements = false
    var strokes = Data()
    var png: Data? = Data("png".utf8)
    var pdf: Data? = Data("pdf".utf8)
    var thumbnail: Data? = Data("mini".utf8)
    private(set) var isFingerDrawingEnabled: Bool?
    private(set) var background: CanvasBackground?
    private(set) var theme: CanvasTheme?
    private(set) var undoCount = 0
    private(set) var smoothCount = 0
    private(set) var redoCount = 0

    var isEmpty: Bool { strokes.isEmpty && shownElements.isEmpty }

    var hasStrokes: Bool { !strokes.isEmpty }

    func showElements(_ elements: [PageElement], selectedID: UUID?) {
        shownElements = elements
        shownSelectedID = selectedID
    }

    func setArrangingElements(_ enabled: Bool) {
        isArrangingElements = enabled
    }

    func currentData() -> Data { strokes }

    func load(_ strokesData: Data) throws {
        strokes = strokesData
        onDrawingChanged?() // PencilKit también avisa al cargar.
    }

    func clear() {
        strokes = Data()
        onDrawingChanged?()
    }

    func undo() { undoCount += 1 }

    func smoothStrokes() {
        smoothCount += 1
        onDrawingChanged?() // Suavizar cambia el dibujo, como un trazo más.
    }

    func redo() { redoCount += 1 }

    func setFingerDrawingEnabled(_ enabled: Bool) {
        isFingerDrawingEnabled = enabled
    }

    func setBackground(_ background: CanvasBackground, theme: CanvasTheme) {
        self.background = background
        self.theme = theme
    }

    func renderPNG() -> Data? {
        isEmpty ? nil : png
    }

    func renderPDF() -> Data? {
        isEmpty ? nil : pdf
    }

    func renderThumbnail() -> Data? {
        isEmpty ? nil : thumbnail
    }

    /// Simula que el usuario dibuja un trazo.
    func simulateStroke(_ data: Data = Data("trazo".utf8)) {
        strokes = data
        onDrawingChanged?()
    }
}
