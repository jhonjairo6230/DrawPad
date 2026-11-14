import Foundation
import Observation

/// Estado y acciones de la pantalla de dibujo (patrón MVVM).
///
/// - Recibe intenciones de la vista (`undo()`, `export()`…).
/// - Habla con el lienzo a través de ``DrawingCanvas`` y con el dominio a
///   través de los casos de uso; nunca con PencilKit, archivos ni Fotos.
/// - Publica estado observable (`isExporting`, `alert`…) que la vista pinta.
///
/// **Autoguardado:** cada cambio de trazos reinicia un temporizador
/// (`autosaveDelay`). Cuando pasa ese tiempo sin cambios se guarda una sola
/// vez (*debounce*). Al salir de la app se guarda lo pendiente de inmediato
/// (``flushPendingSave()``).
@MainActor
@Observable
final class CanvasViewModel {
    private(set) var isFingerDrawingEnabled = false
    private(set) var isExporting = false
    var alert: AlertMessage?

    private let canvas: DrawingCanvas
    private let loadDrawing: LoadDrawingUseCase
    private let saveDrawing: SaveDrawingUseCase
    private let exportDrawing: ExportDrawingUseCase
    private let autosaveDelay: Duration

    @ObservationIgnored private var pendingSave: Task<Void, Never>?
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var isRestoring = false

    init(
        canvas: DrawingCanvas,
        loadDrawing: LoadDrawingUseCase,
        saveDrawing: SaveDrawingUseCase,
        exportDrawing: ExportDrawingUseCase,
        autosaveDelay: Duration = .seconds(1)
    ) {
        self.canvas = canvas
        self.loadDrawing = loadDrawing
        self.saveDrawing = saveDrawing
        self.exportDrawing = exportDrawing
        self.autosaveDelay = autosaveDelay
        canvas.onDrawingChanged = { [weak self] in
            self?.drawingDidChange()
        }
    }

    /// `true` mientras hay cambios sin guardar.
    var hasPendingChanges: Bool { pendingSave != nil }

    // MARK: - Ciclo de vida

    /// Restaura el último dibujo. Solo actúa la primera vez que aparece la pantalla.
    func onAppear() {
        guard !hasLoaded else { return }
        hasLoaded = true
        canvas.setFingerDrawingEnabled(isFingerDrawingEnabled)
        do {
            guard let drawing = try loadDrawing.execute() else { return }
            // Al cargar, el lienzo avisa de un "cambio" que no hay que guardar.
            isRestoring = true
            defer { isRestoring = false }
            try canvas.load(drawing.strokesData)
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    /// Guarda ya lo pendiente (la app pasa a segundo plano).
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
            try saveDrawing.execute(strokesData: canvas.currentData())
        } catch {
            alert = AlertMessage(error: error)
        }
    }
}
