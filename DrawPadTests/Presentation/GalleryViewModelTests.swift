import XCTest
@testable import DrawPad

@MainActor
final class GalleryViewModelTests: XCTestCase {
    private var library: InMemoryLibrary!

    private func makeViewModel(_ notebooks: [Notebook] = []) -> GalleryViewModel {
        library = InMemoryLibrary(notebooks: notebooks)
        return GalleryViewModel(
            listNotebooks: ListNotebooksUseCase(notebooks: library),
            createNotebook: CreateNotebookUseCase(notebooks: library, drawings: library),
            renameNotebook: RenameNotebookUseCase(notebooks: library),
            deleteNotebook: DeleteNotebookUseCase(notebooks: library)
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

    func testDeleteRemovesTheNotebookFromTheList() {
        let kept = Notebook.sample(title: "Se queda")
        let removed = Notebook.sample(title: "Se va")
        let viewModel = makeViewModel([kept, removed])
        viewModel.load()

        viewModel.delete(id: removed.id)

        XCTAssertEqual(viewModel.notebooks.map(\.title), ["Se queda"])
    }
}
