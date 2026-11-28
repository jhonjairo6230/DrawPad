import XCTest
@testable import DrawPad

@MainActor
final class MarkdownPageViewModelTests: XCTestCase {
    private var library: InMemoryLibrary!
    private var store: SpyExportFileStore!
    private var page: Drawing!

    override func setUp() async throws {
        page = Drawing.sample(kind: .markdown, markdown: "# Hola")
        library = InMemoryLibrary(drawings: [page])
        store = SpyExportFileStore()
    }

    private func makeViewModel(autosaveDelay: Duration = .seconds(60)) -> MarkdownPageViewModel {
        MarkdownPageViewModel(
            pageID: page.id,
            shareName: "Física - Hoja 2",
            loadPage: LoadDrawingUseCase(repository: library),
            saveMarkdown: SaveMarkdownUseCase(drawings: library),
            exportMarkdown: ExportMarkdownUseCase(drawings: library, store: store),
            autosaveDelay: autosaveDelay
        )
    }

    func testOnAppearLoadsTheTextAndStartsInReadMode() {
        let viewModel = makeViewModel()

        viewModel.onAppear()

        XCTAssertEqual(viewModel.text, "# Hola")
        XCTAssertEqual(viewModel.mode, .read)
        XCTAssertFalse(viewModel.hasPendingChanges)
    }

    func testOnAppearShowsAnAlertWhenThePageIsGone() throws {
        try library.deleteDrawing(id: page.id)
        let viewModel = makeViewModel()

        viewModel.onAppear()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.drawingNotFound))
    }

    func testTypingIsSavedAfterAPause() async throws {
        let viewModel = makeViewModel(autosaveDelay: .milliseconds(20))
        viewModel.onAppear()

        viewModel.updateText("# Hola\n\nMás")
        XCTAssertTrue(viewModel.hasPendingChanges)
        for _ in 0..<200 where viewModel.hasPendingChanges {
            try await Task.sleep(for: .milliseconds(10))
        }

        XCTAssertFalse(viewModel.hasPendingChanges)
        XCTAssertEqual(library.drawings[page.id]?.markdown, "# Hola\n\nMás")
    }

    func testFlushSavesRightAwayAndDiscardForgets() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        viewModel.updateText("uno")
        viewModel.flushPendingSave()
        XCTAssertEqual(library.drawings[page.id]?.markdown, "uno")

        viewModel.updateText("dos")
        viewModel.discardPendingSave()
        viewModel.flushPendingSave()
        XCTAssertEqual(library.drawings[page.id]?.markdown, "uno")
    }

    func testExportSavesFirstAndSharesAnMdFile() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        viewModel.updateText("# Spec final")

        viewModel.export()

        XCTAssertEqual(viewModel.sharedFile?.url.lastPathComponent, "Física - Hoja 2.md")
        XCTAssertEqual(store.written.first?.data, Data("# Spec final".utf8))
        XCTAssertFalse(viewModel.hasPendingChanges)
    }
}
