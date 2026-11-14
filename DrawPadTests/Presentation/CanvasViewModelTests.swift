import XCTest
@testable import DrawPad

@MainActor
final class CanvasViewModelTests: XCTestCase {
    private var canvas: FakeDrawingCanvas!
    private var repository: InMemoryDrawingRepository!
    private var library: SpyImageLibrary!

    override func setUp() async throws {
        canvas = FakeDrawingCanvas()
        repository = InMemoryDrawingRepository()
        library = SpyImageLibrary()
    }

    private func makeViewModel(autosaveDelay: Duration = .seconds(60)) -> CanvasViewModel {
        CanvasViewModel(
            canvas: canvas,
            loadDrawing: LoadDrawingUseCase(repository: repository),
            saveDrawing: SaveDrawingUseCase(repository: repository),
            exportDrawing: ExportDrawingUseCase(library: library),
            autosaveDelay: autosaveDelay
        )
    }

    // MARK: - Carga

    func testOnAppearRestoresTheSavedDrawingWithoutSavingItAgain() {
        repository.stored = Drawing(strokesData: Data("guardado".utf8), updatedAt: Date())
        let viewModel = makeViewModel()

        viewModel.onAppear()

        XCTAssertEqual(canvas.strokes, Data("guardado".utf8))
        XCTAssertFalse(viewModel.hasPendingChanges)
        XCTAssertEqual(canvas.isFingerDrawingEnabled, false)
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

        canvas.simulateStroke(Data("uno".utf8))
        XCTAssertTrue(viewModel.hasPendingChanges)
        try await waitUntil { self.repository.saveCount == 1 }

        XCTAssertEqual(repository.stored?.strokesData, Data("uno".utf8))
        XCTAssertFalse(viewModel.hasPendingChanges)
    }

    func testSeveralQuickStrokesAreSavedOnlyOnce() async throws {
        let viewModel = makeViewModel(autosaveDelay: .milliseconds(50))
        viewModel.onAppear()

        canvas.simulateStroke(Data("uno".utf8))
        canvas.simulateStroke(Data("dos".utf8))
        canvas.simulateStroke(Data("tres".utf8))
        try await waitUntil { !viewModel.hasPendingChanges }

        XCTAssertEqual(repository.saveCount, 1)
        XCTAssertEqual(repository.stored?.strokesData, Data("tres".utf8))
    }

    func testFlushSavesPendingChangesImmediately() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        canvas.simulateStroke(Data("uno".utf8))

        viewModel.flushPendingSave()

        XCTAssertEqual(repository.stored?.strokesData, Data("uno".utf8))
        XCTAssertFalse(viewModel.hasPendingChanges)
    }

    func testFlushDoesNothingWithoutPendingChanges() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        viewModel.flushPendingSave()

        XCTAssertEqual(repository.saveCount, 0)
    }

    func testClearEmptiesTheCanvasAndSavesTheEmptyDrawing() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        canvas.simulateStroke()
        viewModel.flushPendingSave()

        viewModel.clear()
        viewModel.flushPendingSave()

        XCTAssertTrue(canvas.isEmpty)
        XCTAssertEqual(repository.stored?.strokesData, Data())
    }

    // MARK: - Herramientas

    func testToggleFingerDrawingUpdatesStateAndCanvas() {
        let viewModel = makeViewModel()

        viewModel.toggleFingerDrawing()

        XCTAssertTrue(viewModel.isFingerDrawingEnabled)
        XCTAssertEqual(canvas.isFingerDrawingEnabled, true)
    }

    func testUndoAndRedoAreForwardedToTheCanvas() {
        let viewModel = makeViewModel()

        viewModel.undo()
        viewModel.redo()
        viewModel.redo()

        XCTAssertEqual(canvas.undoCount, 1)
        XCTAssertEqual(canvas.redoCount, 2)
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
