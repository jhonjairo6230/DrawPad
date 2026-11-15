import Foundation
@testable import DrawPad

/// Lienzo falso: sustituye a PencilKit en las pruebas del ViewModel.
@MainActor
final class FakeDrawingCanvas: DrawingCanvas {
    var onDrawingChanged: (() -> Void)?
    var strokes = Data()
    var png: Data? = Data("png".utf8)
    var thumbnail: Data? = Data("mini".utf8)
    private(set) var isFingerDrawingEnabled: Bool?
    private(set) var background: CanvasBackground?
    private(set) var undoCount = 0
    private(set) var redoCount = 0

    var isEmpty: Bool { strokes.isEmpty }

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

    func redo() { redoCount += 1 }

    func setFingerDrawingEnabled(_ enabled: Bool) {
        isFingerDrawingEnabled = enabled
    }

    func setBackground(_ background: CanvasBackground) {
        self.background = background
    }

    func renderPNG() -> Data? {
        isEmpty ? nil : png
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
