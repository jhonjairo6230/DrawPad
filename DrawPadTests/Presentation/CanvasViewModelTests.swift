import XCTest
@testable import DrawPad

@MainActor
final class CanvasViewModelTests: XCTestCase {
    private var canvas: FakeDrawingCanvas!
    private var repository: InMemoryLibrary!
    private var preferences: CanvasPreferences!
    private var library: SpyImageLibrary!
    private var exportStore: SpyExportFileStore!
    private var clipboard: FakeClipboard!
    /// El dibujo abierto en la pantalla; ya existe en el repositorio.
    private var drawing: Drawing!

    override func setUp() async throws {
        drawing = Drawing.sample()
        canvas = FakeDrawingCanvas()
        repository = InMemoryLibrary(drawings: [drawing])
        preferences = CanvasPreferences()
        library = SpyImageLibrary()
        exportStore = SpyExportFileStore()
        clipboard = FakeClipboard()
    }

    private var stored: Drawing? { repository.drawings[drawing.id] }

    private func makeViewModel(autosaveDelay: Duration = .seconds(60)) -> CanvasViewModel {
        CanvasViewModel(
            drawingID: drawing.id,
            shareName: "Física - Hoja 1",
            preferences: preferences,
            canvas: canvas,
            loadDrawing: LoadDrawingUseCase(repository: repository),
            saveDrawing: SaveDrawingUseCase(repository: repository),
            changeBackground: ChangeBackgroundUseCase(repository: repository),
            exportDrawing: ExportDrawingUseCase(library: library),
            prepareShareFile: PrepareShareFileUseCase(store: exportStore),
            elementUseCases: PageElementUseCases(elements: repository, clipboard: clipboard),
            autosaveDelay: autosaveDelay
        )
    }

    // MARK: - Carga

    func testOnAppearLoadsThePageWithoutSavingItAgain() throws {
        drawing.strokesData = Data("guardado".utf8)
        try repository.save(drawing)
        let viewModel = makeViewModel()

        viewModel.onAppear()

        XCTAssertEqual(canvas.strokes, Data("guardado".utf8))
        XCTAssertFalse(viewModel.hasPendingChanges)
        XCTAssertEqual(canvas.isFingerDrawingEnabled, false)
    }

    func testOnAppearShowsAnAlertWhenThePageNoLongerExists() throws {
        try repository.deleteDrawing(id: drawing.id)
        let viewModel = makeViewModel()

        viewModel.onAppear()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.drawingNotFound))
    }

    func testOnAppearShowsAnAlertWhenLoadingFails() {
        repository.error = .storageFailed
        let viewModel = makeViewModel()

        viewModel.onAppear()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.storageFailed))
    }

    // MARK: - Autoguardado

    func testAStrokeIsSavedAfterTheAutosaveDelay() async throws {
        let viewModel = makeViewModel(autosaveDelay: .milliseconds(20))
        viewModel.onAppear()

        let savesBefore = repository.saveCount
        canvas.simulateStroke(Data("uno".utf8))
        XCTAssertTrue(viewModel.hasPendingChanges)
        try await waitUntil { self.repository.saveCount == savesBefore + 1 }

        XCTAssertEqual(stored?.strokesData, Data("uno".utf8))
        XCTAssertEqual(stored?.thumbnailData, Data("mini".utf8))
        XCTAssertFalse(viewModel.hasPendingChanges)
    }

    func testSeveralQuickStrokesAreSavedOnlyOnce() async throws {
        let viewModel = makeViewModel(autosaveDelay: .milliseconds(50))
        viewModel.onAppear()
        let savesBefore = repository.saveCount

        canvas.simulateStroke(Data("uno".utf8))
        canvas.simulateStroke(Data("dos".utf8))
        canvas.simulateStroke(Data("tres".utf8))
        try await waitUntil { !viewModel.hasPendingChanges }

        XCTAssertEqual(repository.saveCount, savesBefore + 1)
        XCTAssertEqual(stored?.strokesData, Data("tres".utf8))
    }

    func testFlushSavesPendingChangesImmediately() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        canvas.simulateStroke(Data("uno".utf8))

        viewModel.flushPendingSave()

        XCTAssertEqual(stored?.strokesData, Data("uno".utf8))
        XCTAssertFalse(viewModel.hasPendingChanges)
    }

    func testFlushDoesNothingWithoutPendingChanges() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        let savesBefore = repository.saveCount

        viewModel.flushPendingSave()

        XCTAssertEqual(repository.saveCount, savesBefore)
    }

    func testClearEmptiesTheCanvasAndSavesTheEmptyDrawing() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        canvas.simulateStroke()
        viewModel.flushPendingSave()

        viewModel.clear()
        viewModel.flushPendingSave()

        XCTAssertTrue(canvas.isEmpty)
        XCTAssertEqual(stored?.strokesData, Data())
        XCTAssertNil(stored?.thumbnailData)
    }

    // MARK: - Fondo

    func testOnAppearAppliesTheSavedBackground() throws {
        drawing.background = .grid
        drawing.theme = .dark
        try repository.save(drawing)
        let viewModel = makeViewModel()

        viewModel.onAppear()

        XCTAssertEqual(viewModel.background, .grid)
        XCTAssertEqual(viewModel.theme, .dark)
        XCTAssertEqual(canvas.background, .grid)
        XCTAssertEqual(canvas.theme, .dark)
    }

    func testSetThemeKeepsThePatternAndSavesItImmediately() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        viewModel.setBackground(.lines)

        viewModel.setTheme(.dark)

        XCTAssertEqual(viewModel.theme, .dark)
        XCTAssertEqual(canvas.theme, .dark)
        XCTAssertEqual(canvas.background, .lines)
        XCTAssertEqual(stored?.theme, .dark)
        XCTAssertEqual(stored?.background, .lines)
    }

    func testSetThemeKeepsTheOldOneWhenSavingFails() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        repository.error = .storageFailed

        viewModel.setTheme(.dark)

        XCTAssertEqual(viewModel.theme, .light)
        XCTAssertEqual(canvas.theme, .light)
        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.storageFailed))
    }

    func testSetBackgroundUpdatesTheCanvasAndSavesItImmediately() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        viewModel.setBackground(.dots)

        XCTAssertEqual(viewModel.background, .dots)
        XCTAssertEqual(canvas.background, .dots)
        XCTAssertEqual(stored?.background, .dots)
    }

    func testSetBackgroundKeepsTheOldOneWhenSavingFails() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        repository.error = .storageFailed

        viewModel.setBackground(.lines)

        XCTAssertEqual(viewModel.background, .blank)
        XCTAssertEqual(canvas.background, .blank)
        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.storageFailed))
    }

    func testAutosaveAfterChangingTheBackgroundKeepsIt() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        viewModel.setBackground(.grid)
        viewModel.setTheme(.dark)

        canvas.simulateStroke()
        viewModel.flushPendingSave()

        XCTAssertEqual(stored?.background, .grid)
        XCTAssertEqual(stored?.theme, .dark)
        XCTAssertEqual(stored?.strokesData, Data("trazo".utf8))
    }

    // MARK: - Herramientas

    func testToggleFingerDrawingUpdatesStateAndCanvas() {
        let viewModel = makeViewModel()

        viewModel.toggleFingerDrawing()

        XCTAssertTrue(viewModel.isFingerDrawingEnabled)
        XCTAssertEqual(canvas.isFingerDrawingEnabled, true)
    }

    func testFingerDrawingIsRememberedWhenAnotherPageOpens() {
        makeViewModel().toggleFingerDrawing()
        let nextPageCanvas = FakeDrawingCanvas()
        canvas = nextPageCanvas

        let nextPage = makeViewModel()
        nextPage.onAppear()

        XCTAssertTrue(nextPage.isFingerDrawingEnabled)
        XCTAssertEqual(nextPageCanvas.isFingerDrawingEnabled, true)
    }

    func testDiscardPendingSaveDropsUnsavedChanges() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        let savesBefore = repository.saveCount
        canvas.simulateStroke()

        viewModel.discardPendingSave()
        viewModel.flushPendingSave()

        XCTAssertFalse(viewModel.hasPendingChanges)
        XCTAssertEqual(repository.saveCount, savesBefore)
    }

    func testUndoAndRedoAreForwardedToTheCanvas() {
        let viewModel = makeViewModel()

        viewModel.undo()
        viewModel.redo()
        viewModel.redo()

        XCTAssertEqual(canvas.undoCount, 1)
        XCTAssertEqual(canvas.redoCount, 2)
    }

    // MARK: - Textos e imágenes

    /// Un ViewModel ya cargado sobre una hoja con estos elementos.
    private func makeLoadedViewModel(elements: [PageElement] = []) throws -> CanvasViewModel {
        for element in elements {
            try repository.save(element)
        }
        let viewModel = makeViewModel()
        viewModel.onAppear()
        return viewModel
    }

    func testOnAppearShowsTheSavedElementsUnderTheStrokes() throws {
        let text = PageElement.sampleText(pageID: drawing.id, "Hola")

        let viewModel = try makeLoadedViewModel(elements: [text, .sampleText("otra hoja")])

        XCTAssertEqual(viewModel.elements, [text])
        XCTAssertEqual(canvas.shownElements, [text])
        XCTAssertFalse(viewModel.isArrangingElements)
        XCTAssertFalse(viewModel.hasPendingChanges)
    }

    func testCommittingANewTextAddsItAtTheVisibleCenterSelectedAndReadyToMove() throws {
        let viewModel = try makeLoadedViewModel()
        canvas.visibleCenter = CGPoint(x: 500, y: 400)
        viewModel.beginNewText()
        let request = try XCTUnwrap(viewModel.textEditor)
        XCTAssertTrue(request.isNew)

        viewModel.commitText("Hola", for: request)

        let added = try XCTUnwrap(viewModel.elements.first)
        XCTAssertEqual(added.content, .text("Hola"))
        XCTAssertEqual(added.frame.midX, 500, accuracy: 0.001)
        XCTAssertEqual(repository.elements[added.id], added)
        XCTAssertEqual(viewModel.selectedElementID, added.id)
        XCTAssertTrue(viewModel.isArrangingElements)
        XCTAssertTrue(canvas.isArrangingElements)
        XCTAssertEqual(canvas.shownElements, [added])
        XCTAssertEqual(canvas.shownSelectedID, added.id)
    }

    func testCommittingABlankTextShowsAnAlertAndAddsNothing() throws {
        let viewModel = try makeLoadedViewModel()
        viewModel.beginNewText()
        let request = try XCTUnwrap(viewModel.textEditor)

        viewModel.commitText("   ", for: request)

        XCTAssertTrue(viewModel.elements.isEmpty)
        XCTAssertFalse(viewModel.isArrangingElements)
        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.emptyText))
    }

    func testEditingTheSelectedTextChangesIt() throws {
        let text = PageElement.sampleText(pageID: drawing.id, "Viejo")
        let viewModel = try makeLoadedViewModel(elements: [text])
        viewModel.setArrangingElements(true)
        canvas.onElementSelected?(text.id)

        viewModel.beginEditingSelectedText()
        let request = try XCTUnwrap(viewModel.textEditor)
        XCTAssertEqual(request.text, "Viejo")
        XCTAssertFalse(request.isNew)
        viewModel.commitText("Nuevo", for: request)

        XCTAssertEqual(viewModel.elements.map(\.content), [.text("Nuevo")])
        XCTAssertEqual(repository.elements[text.id]?.content, .text("Nuevo"))
        XCTAssertEqual(canvas.shownElements.map(\.content), [.text("Nuevo")])
    }

    func testBeginEditingDoesNothingWhenAnImageIsSelected() throws {
        let image = PageElement.sampleImage(pageID: drawing.id)
        let viewModel = try makeLoadedViewModel(elements: [image])
        viewModel.setArrangingElements(true)
        canvas.onElementSelected?(image.id)

        viewModel.beginEditingSelectedText()

        XCTAssertNil(viewModel.textEditor)
    }

    func testPasteAddsTheClipboardImageNoBiggerThanSixtyPercentOfTheScreen() throws {
        let viewModel = try makeLoadedViewModel()
        canvas.viewportSize = CGSize(width: 1000, height: 800)
        clipboard.current = .image(data: Data("img".utf8), size: CGSize(width: 3000, height: 1500))

        viewModel.paste()

        let added = try XCTUnwrap(viewModel.elements.first)
        XCTAssertEqual(added.content, .image(Data("img".utf8)))
        XCTAssertEqual(added.frame.width, 600, accuracy: 0.001)
        XCTAssertEqual(added.frame.height, 300, accuracy: 0.001)
        XCTAssertEqual(viewModel.selectedElementID, added.id)
        XCTAssertTrue(viewModel.isArrangingElements)
    }

    func testPasteWithAnEmptyClipboardShowsAnAlert() throws {
        let viewModel = try makeLoadedViewModel()

        viewModel.paste()

        XCTAssertTrue(viewModel.elements.isEmpty)
        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.clipboardEmpty))
        XCTAssertFalse(viewModel.isArrangingElements)
    }

    func testMovingAnElementOnTheCanvasSavesItsNewFrame() throws {
        let image = PageElement.sampleImage(pageID: drawing.id)
        let viewModel = try makeLoadedViewModel(elements: [image])
        viewModel.setArrangingElements(true)
        let frame = CGRect(x: 300, y: 200, width: 400, height: 200)

        canvas.onElementMoved?(image.id, frame)

        XCTAssertEqual(viewModel.elements.first?.frame, frame)
        XCTAssertEqual(repository.elements[image.id]?.frame, frame)
        XCTAssertEqual(canvas.shownElements.first?.frame, frame)
        XCTAssertEqual(viewModel.selectedElementID, image.id)
    }

    func testAnElementDraggedOffThePageSnapsBackInside() throws {
        let image = PageElement.sampleImage(pageID: drawing.id)
        let viewModel = try makeLoadedViewModel(elements: [image])

        canvas.onElementMoved?(image.id, CGRect(x: -50, y: -20, width: 200, height: 100))

        XCTAssertEqual(canvas.shownElements.first?.frame.origin, .zero)
        XCTAssertEqual(viewModel.elements.first?.frame.origin, .zero)
    }

    func testDeletingTheSelectedElementRemovesIt() throws {
        let kept = PageElement.sampleText(pageID: drawing.id, "se queda", createdAt: Date(timeIntervalSince1970: 1))
        let removed = PageElement.sampleImage(pageID: drawing.id, createdAt: Date(timeIntervalSince1970: 2))
        let viewModel = try makeLoadedViewModel(elements: [kept, removed])
        viewModel.setArrangingElements(true)
        canvas.onElementSelected?(removed.id)

        viewModel.deleteSelectedElement()

        XCTAssertEqual(viewModel.elements, [kept])
        XCTAssertNil(repository.elements[removed.id])
        XCTAssertNil(viewModel.selectedElementID)
        XCTAssertEqual(canvas.shownElements, [kept])
        XCTAssertNil(canvas.shownSelectedID)
    }

    func testLeavingArrangeModeClearsTheSelectionAndRestoresDrawing() throws {
        let text = PageElement.sampleText(pageID: drawing.id)
        let viewModel = try makeLoadedViewModel(elements: [text])
        viewModel.setArrangingElements(true)
        canvas.onElementSelected?(text.id)

        viewModel.setArrangingElements(false)

        XCTAssertFalse(viewModel.isArrangingElements)
        XCTAssertFalse(canvas.isArrangingElements)
        XCTAssertNil(viewModel.selectedElementID)
        XCTAssertNil(canvas.shownSelectedID)
    }

    func testChangingElementsSchedulesASaveSoTheThumbnailIncludesThem() throws {
        let viewModel = try makeLoadedViewModel()
        viewModel.beginNewText()
        let request = try XCTUnwrap(viewModel.textEditor)
        let savesBefore = repository.saveCount

        viewModel.commitText("Hola", for: request)
        XCTAssertTrue(viewModel.hasPendingChanges)
        viewModel.flushPendingSave()

        XCTAssertEqual(repository.saveCount, savesBefore + 1)
        XCTAssertEqual(stored?.thumbnailData, Data("mini".utf8))
    }

    func testAPageWithOnlyTextCanBeShared() throws {
        let text = PageElement.sampleText(pageID: drawing.id)
        let viewModel = try makeLoadedViewModel(elements: [text])

        viewModel.share(as: .png)

        XCTAssertNotNil(viewModel.sharedFile)
        XCTAssertNil(viewModel.alert)
    }

    // MARK: - Figuras y conexiones

    func testInsertingAShapePutsItAtTheVisibleCenterSelectedAndReadyToMove() throws {
        let viewModel = try makeLoadedViewModel()
        canvas.visibleCenter = CGPoint(x: 500, y: 400)

        viewModel.insertShape(.diamond)

        let added = try XCTUnwrap(viewModel.elements.first)
        XCTAssertEqual(added.content, .shape(DiagramShape(kind: .diamond)))
        XCTAssertEqual(added.frame.midX, 500, accuracy: 0.001)
        XCTAssertEqual(repository.elements[added.id], added)
        XCTAssertEqual(viewModel.selectedElementID, added.id)
        XCTAssertTrue(viewModel.isArrangingElements)
        XCTAssertEqual(canvas.shownElements, [added])
    }

    func testRotatingTheSelectedShape() throws {
        let cylinder = PageElement.sampleShape(
            pageID: drawing.id, .cylinder, frame: CGRect(x: 100, y: 100, width: 110, height: 140)
        )
        let viewModel = try makeLoadedViewModel(elements: [cylinder])
        viewModel.setArrangingElements(true)
        canvas.onElementSelected?(cylinder.id)

        viewModel.rotateSelectedShape()

        XCTAssertEqual(viewModel.elements.first?.content, .shape(DiagramShape(kind: .cylinder, quarterTurns: 1)))
        XCTAssertEqual(viewModel.elements.first?.frame.size, CGSize(width: 140, height: 110))
        XCTAssertEqual(canvas.shownElements.first?.frame.size, CGSize(width: 140, height: 110))
    }

    func testEditingAShapeLabelAllowsLeavingItEmpty() throws {
        let shape = PageElement.sampleShape(pageID: drawing.id, label: "API")
        let viewModel = try makeLoadedViewModel(elements: [shape])
        viewModel.setArrangingElements(true)
        canvas.onElementSelected?(shape.id)

        viewModel.beginEditingSelectedText()
        let request = try XCTUnwrap(viewModel.textEditor)
        XCTAssertTrue(request.isShapeLabel)
        XCTAssertEqual(request.text, "API")
        viewModel.commitText("", for: request)

        XCTAssertEqual(viewModel.elements.first?.content, .shape(DiagramShape(kind: .rectangle, label: "")))
        XCTAssertNil(viewModel.alert)
    }

    func testConnectingTwoShapesByTappingTheDestination() throws {
        let api = PageElement.sampleShape(pageID: drawing.id, createdAt: Date(timeIntervalSince1970: 1))
        let db = PageElement.sampleShape(pageID: drawing.id, .cylinder, createdAt: Date(timeIntervalSince1970: 2))
        let viewModel = try makeLoadedViewModel(elements: [api, db])
        viewModel.setArrangingElements(true)
        canvas.onElementSelected?(api.id)

        viewModel.beginConnecting(.arrow)
        XCTAssertTrue(viewModel.isConnecting)
        canvas.onElementSelected?(db.id)

        XCTAssertFalse(viewModel.isConnecting)
        let connector = try XCTUnwrap(viewModel.elements.first(where: \.isConnector))
        XCTAssertEqual(connector.content, .connector(Connector(fromID: api.id, toID: db.id, style: .arrow)))
        XCTAssertEqual(viewModel.selectedElementID, connector.id)
        XCTAssertEqual(canvas.shownElements.count, 3)
        XCTAssertEqual(canvas.shownSelectedID, connector.id)
    }

    func testTappingTheBackgroundOrTheOriginCancelsConnecting() throws {
        let a = PageElement.sampleShape(pageID: drawing.id)
        let b = PageElement.sampleShape(pageID: drawing.id)
        let viewModel = try makeLoadedViewModel(elements: [a, b])
        viewModel.setArrangingElements(true)

        for tap in [nil, a.id] as [UUID?] {
            canvas.onElementSelected?(a.id)
            viewModel.beginConnecting(.line)
            canvas.onElementSelected?(tap)
            XCTAssertFalse(viewModel.isConnecting)
        }
        XCTAssertFalse(viewModel.elements.contains(where: \.isConnector))
    }

    func testConnectingToAConnectorShowsAnAlert() throws {
        let a = PageElement.sampleShape(pageID: drawing.id, createdAt: Date(timeIntervalSince1970: 1))
        let b = PageElement.sampleShape(pageID: drawing.id, createdAt: Date(timeIntervalSince1970: 2))
        let link = PageElement.sampleConnector(pageID: drawing.id, from: a.id, to: b.id)
        let viewModel = try makeLoadedViewModel(elements: [a, b, link])
        viewModel.setArrangingElements(true)
        canvas.onElementSelected?(a.id)

        viewModel.beginConnecting(.arrow)
        canvas.onElementSelected?(link.id)

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.invalidConnection))
        XCTAssertEqual(viewModel.elements.filter(\.isConnector).count, 1)
    }

    func testDeletingAShapeAlsoRemovesItsConnectorsFromTheScreen() throws {
        let a = PageElement.sampleShape(pageID: drawing.id, createdAt: Date(timeIntervalSince1970: 1))
        let b = PageElement.sampleShape(pageID: drawing.id, createdAt: Date(timeIntervalSince1970: 2))
        let link = PageElement.sampleConnector(pageID: drawing.id, from: a.id, to: b.id)
        let viewModel = try makeLoadedViewModel(elements: [a, b, link])
        viewModel.setArrangingElements(true)
        canvas.onElementSelected?(b.id)

        viewModel.deleteSelectedElement()

        XCTAssertEqual(viewModel.elements, [a])
        XCTAssertEqual(canvas.shownElements, [a])
        XCTAssertNil(repository.elements[link.id])
    }

    func testLeavingArrangeModeCancelsAConnectionInProgress() throws {
        let a = PageElement.sampleShape(pageID: drawing.id)
        let viewModel = try makeLoadedViewModel(elements: [a])
        viewModel.setArrangingElements(true)
        canvas.onElementSelected?(a.id)
        viewModel.beginConnecting(.arrow)

        viewModel.setArrangingElements(false)

        XCTAssertFalse(viewModel.isConnecting)
    }

    // MARK: - Suavizar

    func testSmoothStrokesSmoothsTheCanvasAndSavesTheResult() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        canvas.simulateStroke(Data("tembloroso".utf8))
        viewModel.flushPendingSave()
        let savesBefore = repository.saveCount

        viewModel.smoothStrokes()
        XCTAssertTrue(viewModel.hasPendingChanges)
        viewModel.flushPendingSave()

        XCTAssertEqual(canvas.smoothCount, 1)
        XCTAssertEqual(repository.saveCount, savesBefore + 1)
    }

    func testSmoothStrokesDoesNothingOnAnEmptyPage() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        viewModel.smoothStrokes()

        XCTAssertEqual(canvas.smoothCount, 0)
        XCTAssertFalse(viewModel.hasPendingChanges)
    }

    // MARK: - Exportar

    func testExportSendsThePNGToTheLibraryAndConfirms() async {
        let viewModel = makeViewModel()
        canvas.simulateStroke()

        await viewModel.export()

        XCTAssertEqual(library.added, [Data("png".utf8)])
        XCTAssertEqual(viewModel.alert, .exportSucceeded)
        XCTAssertFalse(viewModel.isExporting)
    }

    func testExportWithAnEmptyCanvasShowsAnAlertAndExportsNothing() async {
        let viewModel = makeViewModel()

        await viewModel.export()

        XCTAssertTrue(library.added.isEmpty)
        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.emptyDrawing))
    }

    func testExportShowsTheLibraryError() async {
        library.error = .photoLibraryAccessDenied
        let viewModel = makeViewModel()
        canvas.simulateStroke()

        await viewModel.export()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.photoLibraryAccessDenied))
        XCTAssertFalse(viewModel.isExporting)
    }

    // MARK: - Compartir

    func testShareAsPDFWritesAFileNamedAfterThePageAndOpensTheSheet() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        canvas.simulateStroke()

        viewModel.share(as: .pdf)

        XCTAssertEqual(exportStore.written.map(\.fileName), ["Física - Hoja 1.pdf"])
        XCTAssertEqual(exportStore.written.first?.data, Data("pdf".utf8))
        XCTAssertEqual(viewModel.sharedFile?.url.lastPathComponent, "Física - Hoja 1.pdf")
    }

    func testShareAsPNGUsesThePNGRender() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        canvas.simulateStroke()

        viewModel.share(as: .png)

        XCTAssertEqual(exportStore.written.map(\.fileName), ["Física - Hoja 1.png"])
        XCTAssertEqual(exportStore.written.first?.data, Data("png".utf8))
    }

    func testShareWithAnEmptyCanvasShowsAnAlertAndNoSheet() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        viewModel.share(as: .png)

        XCTAssertNil(viewModel.sharedFile)
        XCTAssertTrue(exportStore.written.isEmpty)
        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.emptyDrawing))
    }

    func testShareShowsAnAlertWhenTheFileCannotBeWritten() {
        exportStore.error = .shareFailed
        let viewModel = makeViewModel()
        viewModel.onAppear()
        canvas.simulateStroke()

        viewModel.share(as: .pdf)

        XCTAssertNil(viewModel.sharedFile)
        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.shareFailed))
    }

    // MARK: - Utilidades

    /// Espera (como máximo 2 s) a que se cumpla una condición.
    private func waitUntil(
        _ condition: @escaping () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        for _ in 0..<200 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("La condición no se cumplió a tiempo", file: file, line: line)
    }
}
