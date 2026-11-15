import Foundation
import Observation

/// Estado y acciones de la pantalla de dibujo (patrón MVVM).
///
/// Trabaja sobre **una** hoja, identificada por `drawingID`.
///
/// - Recibe intenciones de la vista (`undo()`, `export()`…).
/// - Habla con el lienzo a través de ``DrawingCanvas`` y con el dominio a
///   través de los casos de uso; nunca con PencilKit, SwiftData ni Fotos.
/// - Publica estado observable (`background`, `isExporting`, `alert`…).
///
/// **Autoguardado:** cada cambio de trazos reinicia un temporizador
/// (`autosaveDelay`). Cuando pasa ese tiempo sin cambios se guarda una sola
/// vez (*debounce*). Al salir de la hoja o de la app se guarda lo pendiente de
/// inmediato (``flushPendingSave()``).
@MainActor
@Observable
final class CanvasViewModel {
    var isFingerDrawingEnabled: Bool { preferences.isFingerDrawingEnabled }
    private(set) var background = CanvasBackground.blank
    private(set) var theme = CanvasTheme.light
    private(set) var isExporting = false
    var alert: AlertMessage?
    /// Archivo listo para compartir; la vista muestra la hoja mientras no sea `nil`.
    var sharedFile: SharedFile?

    private let drawingID: UUID
    /// Nombre de la hoja para el archivo al compartir ("Cuaderno 1 - Hoja 2").
    private let shareName: String
    private let preferences: CanvasPreferences
    private let canvas: DrawingCanvas
    private let loadDrawing: LoadDrawingUseCase
    private let saveDrawing: SaveDrawingUseCase
    private let changeBackground: ChangeBackgroundUseCase
    private let exportDrawing: ExportDrawingUseCase
    private let prepareShareFile: PrepareShareFileUseCase
    private let autosaveDelay: Duration

    @ObservationIgnored private var pendingSave: Task<Void, Never>?
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var isRestoring = false

    init(
        drawingID: UUID,
        shareName: String,
        preferences: CanvasPreferences,
        canvas: DrawingCanvas,
        loadDrawing: LoadDrawingUseCase,
        saveDrawing: SaveDrawingUseCase,
        changeBackground: ChangeBackgroundUseCase,
        exportDrawing: ExportDrawingUseCase,
        prepareShareFile: PrepareShareFileUseCase,
        autosaveDelay: Duration = .seconds(1)
    ) {
        self.drawingID = drawingID
        self.shareName = shareName
        self.preferences = preferences
        self.canvas = canvas
        self.loadDrawing = loadDrawing
        self.saveDrawing = saveDrawing
        self.changeBackground = changeBackground
        self.exportDrawing = exportDrawing
        self.prepareShareFile = prepareShareFile
        self.autosaveDelay = autosaveDelay
        canvas.onDrawingChanged = { [weak self] in
            self?.drawingDidChange()
        }
    }

    /// `true` mientras hay cambios sin guardar.
    var hasPendingChanges: Bool { pendingSave != nil }

    // MARK: - Ciclo de vida

    /// Carga la hoja en el lienzo. Solo actúa la primera vez que aparece la pantalla.
    func onAppear() {
        guard !hasLoaded else { return }
        hasLoaded = true
        canvas.setFingerDrawingEnabled(isFingerDrawingEnabled)
        do {
            let drawing = try loadDrawing.execute(id: drawingID)
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

    /// Guarda ya lo pendiente (se sale de la hoja o la app pasa a segundo plano).
    func flushPendingSave() {
        guard hasPendingChanges else { return }
        saveNow()
    }

    /// Olvida lo pendiente sin guardarlo (la hoja se acaba de eliminar).
    func discardPendingSave() {
        pendingSave?.cancel()
        pendingSave = nil
    }

    // MARK: - Acciones del usuario

    func undo() { canvas.undo() }

    func redo() { canvas.redo() }

    func toggleFingerDrawing() {
        preferences.isFingerDrawingEnabled.toggle()
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

    /// Convierte la hoja a PNG y la añade a Fotos.
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

    /// Genera el archivo en el formato elegido y abre la hoja de compartir.
    func share(as format: ExportFormat) {
        let data: Data?
        switch format {
        case .png: data = canvas.renderPNG()
        case .pdf: data = canvas.renderPDF()
        }
        do {
            guard !canvas.isEmpty, let data else { throw DrawingError.emptyDrawing }
            let url = try prepareShareFile.execute(name: shareName, format: format, data: data)
            sharedFile = SharedFile(url: url)
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
