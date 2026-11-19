import Foundation
import Observation

/// Estado y acciones de la pantalla para dibujar la portada (patrón MVVM).
///
/// No guarda nada por sí misma: ``finish()`` devuelve el dibujo y quien abrió
/// la pantalla decide qué hacer con él. Así el editor de portada sigue
/// trabajando sobre una copia hasta que el usuario toca "Guardar".
@MainActor
@Observable
final class CoverDrawingViewModel {
    var isFingerDrawingEnabled: Bool { preferences.isFingerDrawingEnabled }
    var alert: AlertMessage?

    private let canvas: DrawingCanvas
    private let initialDrawing: CoverDrawing?
    private let color: CoverColor
    private let preferences: CanvasPreferences

    @ObservationIgnored private var hasLoaded = false

    /// - Parameters:
    ///   - initialDrawing: el dibujo actual de la tapa, para seguir editándolo.
    ///   - color: el color de la tapa, que hace de papel.
    init(canvas: DrawingCanvas, initialDrawing: CoverDrawing?, color: CoverColor, preferences: CanvasPreferences) {
        self.canvas = canvas
        self.initialDrawing = initialDrawing
        self.color = color
        self.preferences = preferences
    }

    func onAppear() {
        guard !hasLoaded else { return }
        hasLoaded = true
        canvas.setPaperColor(color)
        canvas.setFingerDrawingEnabled(isFingerDrawingEnabled)
        guard let strokes = initialDrawing?.strokesData else { return }
        do {
            try canvas.load(strokes)
        } catch {
            alert = AlertMessage(error: DrawingError.storageFailed)
        }
    }

    func undo() { canvas.undo() }

    func redo() { canvas.redo() }

    func clear() { canvas.clear() }

    func toggleFingerDrawing() {
        preferences.isFingerDrawingEnabled.toggle()
        canvas.setFingerDrawingEnabled(isFingerDrawingEnabled)
    }

    /// El dibujo terminado, o `nil` si el lienzo quedó sin trazos (la tapa se
    /// queda sin dibujo).
    func finish() -> CoverDrawing? {
        guard canvas.hasStrokes, let image = canvas.renderStrokesPNG() else { return nil }
        return CoverDrawing(strokesData: canvas.currentData(), imageData: image)
    }
}
