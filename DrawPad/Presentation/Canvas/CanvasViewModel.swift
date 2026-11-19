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
/// **Elementos:** además de los trazos, la hoja tiene textos, imágenes,
/// figuras y conexiones (``PageElement``). Se guardan al momento, cada uno
/// por separado, y se mueven en un modo aparte (`isArrangingElements`) en el
/// que no se dibuja. Unir dos elementos es un paso más dentro de ese modo:
/// se elige el origen, "Conectar", y se toca el destino (`connectionDraft`).
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
    /// Editor de diagramas de Mermaid abierto; la vista lo muestra mientras no
    /// sea `nil`.
    var mermaidEditor: MermaidEditorRequest?
    /// Conexión a medio hacer: ya se eligió el origen y falta tocar el destino.
    private(set) var connectionDraft: ConnectionDraft?

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

    /// Abre el editor con el texto del cuadro o de la figura seleccionados.
    func beginEditingSelectedText() {
        guard let element = selectedElement else { return }
        switch element.content {
        case .text(let text):
            textEditor = TextEditorRequest(elementID: element.id, text: text)
        case .shape(let shape):
            textEditor = TextEditorRequest(elementID: element.id, text: shape.label, isShapeLabel: true)
        case .image, .connector, .mermaid:
            break
        }
    }

    // MARK: - Diagramas de Mermaid

    /// Abre el editor con un diagrama de ejemplo.
    func beginNewMermaid() {
        mermaidEditor = MermaidEditorRequest(elementID: nil, source: MermaidEditorRequest.template)
    }

    /// Abre el editor con el texto del diagrama seleccionado.
    func beginEditingSelectedMermaid() {
        guard let element = selectedElement, case .mermaid(let diagram) = element.content else { return }
        mermaidEditor = MermaidEditorRequest(elementID: element.id, source: diagram.source)
    }

    /// Guarda lo que devolvió el editor: un diagrama nuevo en el centro de lo
    /// visible, o el cambio de uno existente.
    func commitMermaid(source: String, snapshot: MermaidSnapshot, for request: MermaidEditorRequest) {
        let viewport = canvas.viewportSize
        // Recién dibujado, un diagrama ocupa como mucho el 80 % de la pantalla.
        let maxSize = CGSize(width: viewport.width * 0.8, height: viewport.height * 0.8)
        performOnElements {
            if let elementID = request.elementID {
                let updated = try elementUseCases.updateMermaid.execute(
                    id: elementID, source: source, image: snapshot.image,
                    imageSize: snapshot.size, maxSize: maxSize
                )
                replaceElement(updated)
            } else {
                let added = try elementUseCases.addMermaid.execute(
                    pageID: drawingID, source: source, image: snapshot.image,
                    imageSize: snapshot.size, centeredAt: canvas.visibleCenter, maxSize: maxSize
                )
                insertAndSelect(added)
            }
        }
    }

    // MARK: - Figuras y conexiones

    var isConnecting: Bool { connectionDraft != nil }

    /// Añade una figura en el centro de lo que se está viendo.
    func insertShape(_ kind: ShapeKind) {
        performOnElements {
            let added = try elementUseCases.addShape.execute(
                pageID: drawingID, kind: kind, centeredAt: canvas.visibleCenter
            )
            insertAndSelect(added)
        }
    }

    /// Gira la figura seleccionada un cuarto de vuelta.
    func rotateSelectedShape() {
        guard let element = selectedElement, element.isShape else { return }
        performOnElements {
            let rotated = try elementUseCases.rotate.execute(id: element.id)
            replaceElement(rotated)
        }
    }

    /// Empieza a unir el elemento seleccionado con otro: el siguiente que se
    /// toque será el destino.
    func beginConnecting(_ style: ConnectorStyle) {
        guard let element = selectedElement, !element.isConnector else { return }
        connectionDraft = ConnectionDraft(fromID: element.id, style: style)
    }

    func cancelConnecting() {
        connectionDraft = nil
    }

    /// Une el origen de `draft` con `destinationID` y selecciona la conexión.
    private func finishConnecting(_ draft: ConnectionDraft, to destinationID: UUID) {
        performOnElements {
            let connector = try elementUseCases.connect.execute(
                pageID: drawingID, from: draft.fromID, to: destinationID, style: draft.style
            )
            elements = try elementUseCases.list.execute(pageID: drawingID)
            selectedElementID = connector.id
        }
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
        if !enabled {
            selectedElementID = nil
            connectionDraft = nil
        }
        canvas.setArrangingElements(enabled)
        refreshCanvasElements()
    }

    func deleteSelectedElement() {
        guard let id = selectedElementID else { return }
        connectionDraft = nil
        performOnElements {
            try elementUseCases.delete.execute(id: id)
            // Se vuelve a leer: al quitar una figura se van también sus conexiones.
            elements = try elementUseCases.list.execute(pageID: drawingID)
            selectedElementID = nil
        }
    }

    /// El usuario tocó un elemento (o el fondo) en el modo de mover. Si se
    /// estaba uniendo, ese toque elige el destino; tocar el fondo o el mismo
    /// origen lo cancela.
    private func selectElement(_ id: UUID?) {
        if let draft = connectionDraft {
            connectionDraft = nil
            if let id, id != draft.fromID {
                finishConnecting(draft, to: id)
                return
            }
        }
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

/// Una conexión a medio hacer: el origen elegido y el tipo de línea.
struct ConnectionDraft: Equatable {
    let fromID: UUID
    let style: ConnectorStyle
}
