import XCTest
@testable import DrawPad

@MainActor
final class GalleryViewModelTests: XCTestCase {
    private var library: InMemoryLibrary!
    private var coder: InMemoryArchiveCoder!
    private var reader: FakeFileReader!
    private var store: SpyExportFileStore!

    private func makeViewModel(_ notebooks: [Notebook] = []) -> GalleryViewModel {
        library = InMemoryLibrary(notebooks: notebooks)
        coder = InMemoryArchiveCoder()
        reader = FakeFileReader()
        store = SpyExportFileStore()
        return GalleryViewModel(
            listNotebooks: ListNotebooksUseCase(notebooks: library),
            createNotebook: CreateNotebookUseCase(notebooks: library, drawings: library),
            renameNotebook: RenameNotebookUseCase(notebooks: library),
            deleteNotebook: DeleteNotebookUseCase(notebooks: library),
            changeCover: ChangeCoverUseCase(notebooks: library),
            exportNotebook: ExportNotebookUseCase(
                notebooks: library, drawings: library, elements: library, coder: coder, store: store
            ),
            importNotebook: ImportNotebookUseCase(
                notebooks: library, drawings: library, elements: library, coder: coder, reader: reader
            )
        )
    }

    func testLoadShowsNotebooksMostRecentFirst() {
        let viewModel = makeViewModel([
            .sample(title: "Viejo", createdAt: Date(timeIntervalSince1970: 1)),
            .sample(title: "Nuevo", createdAt: Date(timeIntervalSince1970: 2)),
        ])

        viewModel.load()

        XCTAssertEqual(viewModel.notebooks.map(\.title), ["Nuevo", "Viejo"])
    }

    func testLoadShowsAnAlertWhenStorageFails() {
        let viewModel = makeViewModel()
        library.error = .storageFailed

        viewModel.load()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.storageFailed))
        XCTAssertTrue(viewModel.notebooks.isEmpty)
    }

    func testCreateAddsANotebookWithOnePageAndReturnsItsID() throws {
        let viewModel = makeViewModel()

        let id = try XCTUnwrap(viewModel.create())

        XCTAssertEqual(viewModel.notebooks.map(\.id), [id])
        XCTAssertEqual(viewModel.notebooks.first?.title, "Cuaderno 1")
        XCTAssertEqual(viewModel.notebooks.first?.pageCount, 1)
    }

    func testCreateReturnsNilAndShowsAnAlertWhenStorageFails() {
        let viewModel = makeViewModel()
        library.error = .storageFailed

        XCTAssertNil(viewModel.create())
        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.storageFailed))
    }

    func testRenameUpdatesTheList() {
        let notebook = Notebook.sample(title: "Viejo")
        let viewModel = makeViewModel([notebook])
        viewModel.load()

        viewModel.rename(id: notebook.id, to: "Física")

        XCTAssertEqual(viewModel.notebooks.map(\.title), ["Física"])
    }

    func testRenameWithABlankTitleShowsAnAlertAndKeepsTheOldTitle() {
        let notebook = Notebook.sample(title: "Viejo")
        let viewModel = makeViewModel([notebook])
        viewModel.load()

        viewModel.rename(id: notebook.id, to: "  ")

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.invalidTitle))
        XCTAssertEqual(viewModel.notebooks.map(\.title), ["Viejo"])
    }

    func testChangeCoverUpdatesTheList() {
        let notebook = Notebook.sample(title: "Física")
        let viewModel = makeViewModel([notebook])
        viewModel.load()
        let cover = NotebookCover(color: .teal, style: .spine)

        viewModel.changeCover(id: notebook.id, to: cover)

        XCTAssertEqual(viewModel.notebooks.map(\.cover), [cover])
        XCTAssertEqual(viewModel.notebooks.map(\.title), ["Física"])
    }

    func testChangeCoverShowsAnAlertWhenStorageFails() {
        let notebook = Notebook.sample()
        let viewModel = makeViewModel([notebook])
        viewModel.load()
        library.error = .storageFailed

        viewModel.changeCover(id: notebook.id, to: NotebookCover(color: .red, style: .plain))

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.storageFailed))
        XCTAssertEqual(viewModel.notebooks.map(\.cover), [.standard])
    }

    func testExportOpensTheShareSheetWithTheFile() throws {
        let notebook = Notebook.sample(title: "Física")
        let viewModel = makeViewModel([notebook])
        try library.save(Drawing.sample(notebookID: notebook.id))

        viewModel.export(id: notebook.id)

        XCTAssertEqual(viewModel.sharedFile?.url.lastPathComponent, "Física.drawpad")
        XCTAssertNil(viewModel.alert)
    }

    func testImportingANewNotebookAddsItAndSaysSo() throws {
        let viewModel = makeViewModel()
        let notebook = Notebook.sample(title: "Del iPad")
        coder.decodeResult = .success(NotebookBundle(
            notebook: notebook, pages: [Drawing.sample(notebookID: notebook.id)], elements: []
        ))

        viewModel.importNotebook(from: URL(fileURLWithPath: "/tmp/Del iPad.drawpad"))

        XCTAssertEqual(viewModel.notebooks.map(\.title), ["Del iPad"])
        XCTAssertEqual(viewModel.alert?.title, "Cuaderno importado")
    }

    func testImportingAgainSaysTheNotebookWasUpdated() throws {
        let notebook = Notebook.sample(title: "Del iPad")
        let viewModel = makeViewModel([notebook])
        coder.decodeResult = .success(NotebookBundle(
            notebook: notebook, pages: [Drawing.sample(notebookID: notebook.id)], elements: []
        ))

        viewModel.importNotebook(from: URL(fileURLWithPath: "/tmp/Del iPad.drawpad"))

        XCTAssertEqual(viewModel.notebooks.count, 1)
        XCTAssertEqual(viewModel.alert?.title, "Cuaderno actualizado")
    }

    func testImportingABrokenFileShowsTheError() {
        let viewModel = makeViewModel()
        coder.decodeResult = .failure(.importFailed)

        viewModel.importNotebook(from: URL(fileURLWithPath: "/tmp/roto.drawpad"))

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.importFailed))
        XCTAssertTrue(viewModel.notebooks.isEmpty)
    }

    func testDeleteRemovesTheNotebookFromTheList() {
        let kept = Notebook.sample(title: "Se queda")
        let removed = Notebook.sample(title: "Se va")
        let viewModel = makeViewModel([kept, removed])
        viewModel.load()

        viewModel.delete(id: removed.id)

        XCTAssertEqual(viewModel.notebooks.map(\.title), ["Se queda"])
    }
}
