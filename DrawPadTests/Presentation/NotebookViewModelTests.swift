import XCTest
@testable import DrawPad

@MainActor
final class NotebookViewModelTests: XCTestCase {
    private var library: InMemoryLibrary!
    private var notebook: Notebook!
    /// Todas las hojas que el ViewModel ha abierto, en orden.
    private var sessions: [FakePageSession] = []
    private let reader = FakeFileReader()

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    /// Un cuaderno "Física" con `pageCount` hojas, ya cargado.
    private func makeLoadedViewModel(pageCount: Int) -> (NotebookViewModel, [Drawing]) {
        notebook = Notebook.sample(title: "Física")
        let pages = (0..<pageCount).map { index in
            Drawing.sample(notebookID: notebook.id, createdAt: date(TimeInterval(index)))
        }
        library = InMemoryLibrary(notebooks: [notebook], drawings: pages)
        sessions = []
        let viewModel = makeViewModel()
        viewModel.onAppear()
        return (viewModel, pages)
    }

    private func makeViewModel() -> NotebookViewModel {
        NotebookViewModel(
            notebookID: notebook.id,
            loadNotebook: LoadNotebookUseCase(notebooks: library),
            listPages: ListPagesUseCase(drawings: library),
            // Reloj posterior a las hojas de ejemplo: la nueva queda al final.
            addPage: AddPageUseCase(drawings: library, now: { Date(timeIntervalSince1970: 1_000) }),
            addMarkdownPage: AddMarkdownPageUseCase(drawings: library, now: { Date(timeIntervalSince1970: 1_000) }),
            importMarkdownPage: ImportMarkdownPageUseCase(
                reader: reader,
                addPage: AddMarkdownPageUseCase(drawings: library, now: { Date(timeIntervalSince1970: 1_000) })
            ),
            deletePage: DeletePageUseCase(drawings: library),
            makeSession: { [unowned self] page, shareName in
                let session = FakePageSession(pageID: page.id, kind: page.kind, shareName: shareName)
                self.sessions.append(session)
                return session
            }
        )
    }

    private func currentSession(of viewModel: NotebookViewModel) -> FakePageSession? {
        viewModel.session as? FakePageSession
    }

    // MARK: - Carga

    func testOnAppearLoadsTheNotebookAndOpensItsFirstPage() {
        let (viewModel, pages) = makeLoadedViewModel(pageCount: 3)

        XCTAssertEqual(viewModel.title, "Física")
        XCTAssertEqual(viewModel.pageLabel, "Hoja 1 de 3")
        XCTAssertEqual(currentSession(of: viewModel)?.pageID, pages[0].id)
        XCTAssertEqual(currentSession(of: viewModel)?.shareName, "Física - Hoja 1")
        XCTAssertFalse(viewModel.canGoToPreviousPage)
        XCTAssertTrue(viewModel.canGoToNextPage)
    }

    func testOnAppearTwiceDoesNotReopenThePage() {
        let (viewModel, _) = makeLoadedViewModel(pageCount: 2)

        viewModel.onAppear()

        XCTAssertEqual(sessions.count, 1)
    }

    func testOnAppearShowsAnAlertWhenTheNotebookDoesNotExist() {
        notebook = Notebook.sample()
        library = InMemoryLibrary()
        let viewModel = makeViewModel()

        viewModel.onAppear()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.notebookNotFound))
        XCTAssertNil(viewModel.session)
    }

    // MARK: - Pasar de hoja

    func testGoingToTheNextPageSavesTheCurrentOneAndOpensTheNext() {
        let (viewModel, pages) = makeLoadedViewModel(pageCount: 3)

        viewModel.goToNextPage()

        XCTAssertEqual(sessions[0].flushCount, 1)
        XCTAssertEqual(viewModel.pageLabel, "Hoja 2 de 3")
        XCTAssertEqual(currentSession(of: viewModel)?.pageID, pages[1].id)
        XCTAssertEqual(currentSession(of: viewModel)?.shareName, "Física - Hoja 2")
        XCTAssertTrue(viewModel.canGoToPreviousPage)
    }

    func testGoingBackOpensThePreviousPage() {
        let (viewModel, pages) = makeLoadedViewModel(pageCount: 2)
        viewModel.goToNextPage()

        viewModel.goToPreviousPage()

        XCTAssertEqual(currentSession(of: viewModel)?.pageID, pages[0].id)
        XCTAssertEqual(viewModel.pageLabel, "Hoja 1 de 2")
    }

    func testCannotGoBeyondTheFirstOrLastPage() {
        let (viewModel, _) = makeLoadedViewModel(pageCount: 1)

        viewModel.goToPreviousPage()
        viewModel.goToNextPage()

        XCTAssertEqual(sessions.count, 1)
        XCTAssertFalse(viewModel.canGoToPreviousPage)
        XCTAssertFalse(viewModel.canGoToNextPage)
    }

    // MARK: - Añadir hojas

    func testAddPageAppendsOneAndOpensIt() throws {
        let (viewModel, _) = makeLoadedViewModel(pageCount: 2)

        viewModel.addPage()

        XCTAssertEqual(viewModel.pages.count, 3)
        XCTAssertEqual(viewModel.pageLabel, "Hoja 3 de 3")
        XCTAssertEqual(currentSession(of: viewModel)?.pageID, viewModel.pages.last?.id)
        XCTAssertEqual(sessions[0].flushCount, 1)
        XCTAssertEqual(try library.listDrawings(notebookID: notebook.id).count, 3)
    }

    func testAddPageShowsAnAlertAndStaysOnThePageWhenStorageFails() {
        let (viewModel, pages) = makeLoadedViewModel(pageCount: 1)
        library.error = .storageFailed

        viewModel.addPage()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.storageFailed))
        XCTAssertEqual(currentSession(of: viewModel)?.pageID, pages[0].id)
        XCTAssertEqual(viewModel.pages.count, 1)
    }

    // MARK: - Hojas Markdown

    func testAddingAMarkdownPageOpensItAsMarkdown() throws {
        let (viewModel, _) = makeLoadedViewModel(pageCount: 1)

        viewModel.addPage(.markdown)

        XCTAssertEqual(viewModel.pageLabel, "Hoja 2 de 2")
        XCTAssertEqual(currentSession(of: viewModel)?.kind, .markdown)
        XCTAssertEqual(viewModel.pages.last?.kind, .markdown)
        let page = try XCTUnwrap(library.drawings[viewModel.pages[1].id])
        XCTAssertEqual(page.markdown, AddMarkdownPageUseCase.template)
    }

    func testImportingAMarkdownFileAddsItAsANewPage() {
        let (viewModel, _) = makeLoadedViewModel(pageCount: 1)
        reader.data = Data("# Spec\n\nTexto".utf8)

        viewModel.importMarkdown(from: URL(fileURLWithPath: "/tmp/spec.md"))

        XCTAssertEqual(viewModel.pageLabel, "Hoja 2 de 2")
        XCTAssertEqual(currentSession(of: viewModel)?.kind, .markdown)
        XCTAssertEqual(library.drawings[viewModel.pages[1].id]?.markdown, "# Spec\n\nTexto")
    }

    func testImportingSomethingThatIsNotTextShowsAnAlert() {
        let (viewModel, _) = makeLoadedViewModel(pageCount: 1)
        reader.data = Data([0xFF, 0xFE, 0xFD])

        viewModel.importMarkdown(from: URL(fileURLWithPath: "/tmp/foto.md"))

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.importFailed))
        XCTAssertEqual(viewModel.pages.count, 1)
    }

    func testAMarkdownPageAlreadyInTheNotebookOpensAsMarkdown() throws {
        let (viewModel, _) = makeLoadedViewModel(pageCount: 1)
        try library.save(Drawing.sample(notebookID: notebook.id, createdAt: date(5), kind: .markdown, markdown: "# Hola"))
        viewModel.addPage() // fuerza a releer las hojas
        viewModel.goToPreviousPage()

        XCTAssertEqual(currentSession(of: viewModel)?.kind, .markdown)
    }

    // MARK: - Eliminar hojas

    func testDeletingAMiddlePageOpensTheOneThatTakesItsPlace() {
        let (viewModel, pages) = makeLoadedViewModel(pageCount: 3)
        viewModel.goToNextPage()
        let deleted = sessions[1]

        viewModel.deleteCurrentPage()

        XCTAssertNil(library.drawings[pages[1].id])
        XCTAssertEqual(viewModel.pageLabel, "Hoja 2 de 2")
        XCTAssertEqual(currentSession(of: viewModel)?.pageID, pages[2].id)
        // Lo pendiente de la hoja eliminada se descarta, no se guarda.
        XCTAssertEqual(deleted.discardCount, 1)
        XCTAssertEqual(deleted.flushCount, 0)
    }

    func testDeletingTheLastPageOfTheListOpensThePreviousOne() {
        let (viewModel, pages) = makeLoadedViewModel(pageCount: 2)
        viewModel.goToNextPage()

        viewModel.deleteCurrentPage()

        XCTAssertEqual(viewModel.pageLabel, "Hoja 1 de 1")
        XCTAssertEqual(currentSession(of: viewModel)?.pageID, pages[0].id)
    }

    func testTheOnlyPageCannotBeDeleted() {
        let (viewModel, pages) = makeLoadedViewModel(pageCount: 1)

        XCTAssertFalse(viewModel.canDeletePage)
        viewModel.deleteCurrentPage()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.lastPage))
        XCTAssertNotNil(library.drawings[pages[0].id])
        XCTAssertEqual(currentSession(of: viewModel)?.pageID, pages[0].id)
        XCTAssertEqual(sessions[0].discardCount, 0)
    }

    // MARK: - Salir

    func testFlushPendingSaveIsForwardedToTheOpenPage() {
        let (viewModel, _) = makeLoadedViewModel(pageCount: 1)

        viewModel.flushPendingSave()

        XCTAssertEqual(sessions[0].flushCount, 1)
    }
}
