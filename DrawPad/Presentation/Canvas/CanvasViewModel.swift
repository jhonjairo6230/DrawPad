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
/// **Textos e imágenes:** además de los trazos, la hoja tiene elementos
/// (``PageElement``). Se guardan al momento, cada uno por separado, y se
/// mueven en un modo aparte (`isArrangingElements`) en el que no se dibuja.
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

    /// Textos e imágenes de la hoja, del fondo hacia arriba.
    private(set) var elements: [PageElement] = []
    private(set) var selectedElementID: UUID?
    /// `true`: los toques mueven textos e imágenes en lugar de dibujar.
    private(set) var isArrangingElements = false
    /// Editor de texto abierto; la vista lo muestra mientras no sea `nil`.
    var textEditor: TextEditorRequest?

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
    private let elementUseCases: PageElementUseCases
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
        elementUseCases: PageElementUseCases,
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
        self.elementUseCases = elementUseCases
        self.autosaveDelay = autosaveDelay
        canvas.onDrawingChanged = { [weak self] in
            self?.drawingDidChange()
        }
        canvas.onElementMoved = { [weak self] id, frame in
            self?.elementMoved(id: id, to: frame)
        }
        canvas.onElementSelected = { [weak self] id in
            self?.selectElement(id)
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
            elements = try elementUseCases.list.execute(pageID: drawingID)
            refreshCanvasElements()
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

    /// Reduce el temblor de los trazos de la hoja. El cambio entra por el
    /// autoguardado, como cualquier otro, y se puede deshacer.
    func smoothStrokes() {
        guard canvas.hasStrokes else { return }
        canvas.smoothStrokes()
    }

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

    // MARK: - Textos e imágenes

    var selectedElement: PageElement? {
        elements.first { $0.id == selectedElementID }
    }

    /// Abre el editor para escribir un cuadro de texto nuevo.
    func beginNewText() {
        textEditor = TextEditorRequest(elementID: nil, text: "")
    }

    /// Abre el editor con el texto del cuadro seleccionado.
    func beginEditingSelectedText() {
        guard let element = selectedElement, case .text(let text) = element.content else { return }
        textEditor = TextEditorRequest(elementID: element.id, text: text)
    }

    /// Guarda lo escrito en el editor: crea el cuadro o cambia el existente.
    func commitText(_ text: String, for request: TextEditorRequest) {
        performOnElements {
            if let elementID = request.elementID {
                let updated = try elementUseCases.updateText.execute(id: elementID, text: text)
                replaceElement(updated)
            } else {
                let added = try elementUseCases.addText.execute(
                    pageID: drawingID, text: text, centeredAt: canvas.visibleCenter
                )
                insertAndSelect(added)
            }
        }
    }

    /// Pega el texto o la imagen del portapapeles en el centro de lo visible.
    func paste() {
        performOnElements {
            let viewport = canvas.viewportSize
            let added = try elementUseCases.paste.execute(
                pageID: drawingID,
                centeredAt: canvas.visibleCenter,
                // Recién pegada, una imagen ocupa como mucho el 60 % de la pantalla.
                maxImageSize: CGSize(width: viewport.width * 0.6, height: viewport.height * 0.6)
            )
            insertAndSelect(added)
        }
    }

    /// Entra o sale del modo en que los toques mueven textos e imágenes.
    func setArrangingElements(_ enabled: Bool) {
        guard enabled != isArrangingElements else { return }
        isArrangingElements = enabled
        if !enabled { selectedElementID = nil }
        canvas.setArrangingElements(enabled)
        refreshCanvasElements()
    }

    func deleteSelectedElement() {
        guard let id = selectedElementID else { return }
        performOnElements {
            try elementUseCases.delete.execute(id: id)
            elements.removeAll { $0.id == id }
            selectedElementID = nil
        }
    }

    /// El usuario tocó un elemento (o el fondo) en el modo de mover.
    private func selectElement(_ id: UUID?) {
        selectedElementID = id
        refreshCanvasElements()
    }

    /// El usuario soltó un elemento en otro sitio o con otro tamaño.
    private func elementMoved(id: UUID, to frame: CGRect) {
        performOnElements {
            let moved = try elementUseCases.move.execute(id: id, frame: frame)
            replaceElement(moved)
            selectedElementID = id
        }
    }

    /// Recién añadido, un elemento queda seleccionado y listo para moverlo:
    /// casi nunca cae justo donde se quería.
    private func insertAndSelect(_ element: PageElement) {
        elements.append(element)
        selectedElementID = element.id
        if !isArrangingElements {
            isArrangingElements = true
            canvas.setArrangingElements(true)
        }
    }

    private func replaceElement(_ element: PageElement) {
        guard let index = elements.firstIndex(where: { $0.id == element.id }) else { return }
        elements[index] = element
    }

    /// Ejecuta un cambio en los elementos; después repinta el lienzo (también
    /// si falló, para deshacer lo que el gesto dejó a medias) y programa un
    /// guardado, porque la miniatura de la hoja incluye los elementos.
    private func performOnElements(_ operation: () throws -> Void) {
        do {
            try operation()
            scheduleAutosave()
        } catch {
            alert = AlertMessage(error: error)
        }
        refreshCanvasElements()
    }

    private func refreshCanvasElements() {
        canvas.showElements(elements, selectedID: selectedElementID)
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
