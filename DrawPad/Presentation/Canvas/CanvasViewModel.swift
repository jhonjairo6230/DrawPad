import Foundation
import Observation

/// Estado y acciones de la pantalla de dibujo (patrón MVVM).
///
/// Trabaja sobre **un** dibujo, identificado por `drawingID`.
///
/// - Recibe intenciones de la vista (`undo()`, `export()`…).
/// - Habla con el lienzo a través de ``DrawingCanvas`` y con el dominio a
///   través de los casos de uso; nunca con PencilKit, SwiftData ni Fotos.
/// - Publica estado observable (`title`, `isExporting`, `alert`…).
///
/// **Autoguardado:** cada cambio de trazos reinicia un temporizador
/// (`autosaveDelay`). Cuando pasa ese tiempo sin cambios se guarda una sola
/// vez (*debounce*). Al salir del dibujo o de la app se guarda lo pendiente de
/// inmediato (``flushPendingSave()``).
@MainActor
@Observable
final class CanvasViewModel {
    private(set) var title = ""
    private(set) var isFingerDrawingEnabled = false
    private(set) var background = CanvasBackground.blank
    private(set) var theme = CanvasTheme.light
    private(set) var isExporting = false
    var alert: AlertMessage?

    private let drawingID: UUID
    private let canvas: DrawingCanvas
    private let loadDrawing: LoadDrawingUseCase
    private let saveDrawing: SaveDrawingUseCase
    private let changeBackground: ChangeBackgroundUseCase
    private let exportDrawing: ExportDrawingUseCase
    private let autosaveDelay: Duration

    @ObservationIgnored private var pendingSave: Task<Void, Never>?
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var isRestoring = false

    init(
        drawingID: UUID,
        canvas: DrawingCanvas,
        loadDrawing: LoadDrawingUseCase,
        saveDrawing: SaveDrawingUseCase,
        changeBackground: ChangeBackgroundUseCase,
        exportDrawing: ExportDrawingUseCase,
        autosaveDelay: Duration = .seconds(1)
    ) {
        self.drawingID = drawingID
        self.canvas = canvas
        self.loadDrawing = loadDrawing
        self.saveDrawing = saveDrawing
        self.changeBackground = changeBackground
        self.exportDrawing = exportDrawing
        self.autosaveDelay = autosaveDelay
        canvas.onDrawingChanged = { [weak self] in
            self?.drawingDidChange()
        }
    }

    /// `true` mientras hay cambios sin guardar.
    var hasPendingChanges: Bool { pendingSave != nil }

    // MARK: - Ciclo de vida

    /// Carga el dibujo en el lienzo. Solo actúa la primera vez que aparece la pantalla.
    func onAppear() {
        guard !hasLoaded else { return }
        hasLoaded = true
        canvas.setFingerDrawingEnabled(isFingerDrawingEnabled)
        do {
            let drawing = try loadDrawing.execute(id: drawingID)
            title = drawing.title
            background = drawing.background
            theme = drawing.theme
            canvas.setBackground(background, theme: theme)
            // Al cargar, el lienzo avisa de un "cambio" que no hay que guardar.
            isRestoring = true
            defer { isRestoring = false }
            try canvas.load(drawing.strokesData)
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    /// Guarda ya lo pendiente (se sale del dibujo o la app pasa a segundo plano).
    func flushPendingSave() {
        guard hasPendingChanges else { return }
        saveNow()
    }

    // MARK: - Acciones del usuario

    func undo() { canvas.undo() }

    func redo() { canvas.redo() }

    func toggleFingerDrawing() {
        isFingerDrawingEnabled.toggle()
        canvas.setFingerDrawingEnabled(isFingerDrawingEnabled)
    }

    /// Cambia el patrón del papel (cuadrícula, líneas…).
    func setBackground(_ newBackground: CanvasBackground) {
        changePaper(background: newBackground, theme: theme)
    }

    /// Cambia entre papel claro y oscuro.
    func setTheme(_ newTheme: CanvasTheme) {
        changePaper(background: background, theme: newTheme)
    }

    /// Guarda el papel al momento (no espera al autoguardado) y, solo si se
    /// guardó, lo aplica al lienzo.
    private func changePaper(background newBackground: CanvasBackground, theme newTheme: CanvasTheme) {
        guard newBackground != background || newTheme != theme else { return }
        do {
            try changeBackground.execute(id: drawingID, background: newBackground, theme: newTheme)
            background = newBackground
            theme = newTheme
            canvas.setBackground(newBackground, theme: newTheme)
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    func clear() {
        canvas.clear()
        scheduleAutosave()
    }

    /// Convierte el dibujo a PNG y lo añade a Fotos.
    func export() async {
        guard !isExporting else { return }
        guard !canvas.isEmpty, let png = canvas.renderPNG() else {
            alert = AlertMessage(error: DrawingError.emptyDrawing)
            return
        }
        isExporting = true
        defer { isExporting = false }
        do {
            try await exportDrawing.execute(pngData: png)
            alert = .exportSucceeded
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    // MARK: - Autoguardado

    private func drawingDidChange() {
        guard !isRestoring else { return }
        scheduleAutosave()
    }

    private func scheduleAutosave() {
        pendingSave?.cancel()
        let delay = autosaveDelay
        pendingSave = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return // Cancelada: llegó otro cambio antes de tiempo.
            }
            self?.saveNow()
        }
    }

    private func saveNow() {
        pendingSave?.cancel()
        pendingSave = nil
        do {
            try saveDrawing.execute(
                id: drawingID,
                strokesData: canvas.currentData(),
                thumbnailData: canvas.renderThumbnail()
            )
        } catch {
            alert = AlertMessage(error: error)
        }
    }
}
