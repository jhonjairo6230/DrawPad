import XCTest
@testable import DrawPad

@MainActor
final class GalleryViewModelTests: XCTestCase {
    private var repository: InMemoryDrawingRepository!

    private func makeViewModel(_ drawings: [Drawing] = []) -> GalleryViewModel {
        repository = InMemoryDrawingRepository(drawings)
        return GalleryViewModel(
            listDrawings: ListDrawingsUseCase(repository: repository),
            createDrawing: CreateDrawingUseCase(repository: repository),
            renameDrawing: RenameDrawingUseCase(repository: repository),
            deleteDrawing: DeleteDrawingUseCase(repository: repository)
        )
    }

    func testLoadShowsDrawingsNewestFirst() {
        let viewModel = makeViewModel([
            .sample(title: "Viejo", updatedAt: Date(timeIntervalSince1970: 1)),
            .sample(title: "Nuevo", updatedAt: Date(timeIntervalSince1970: 2)),
        ])

        viewModel.load()

        XCTAssertEqual(viewModel.drawings.map(\.title), ["Nuevo", "Viejo"])
    }

    func testLoadShowsAnAlertWhenStorageFails() {
        let viewModel = makeViewModel()
        repository.error = .storageFailed

        viewModel.load()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.storageFailed))
        XCTAssertTrue(viewModel.drawings.isEmpty)
    }

    func testCreateAddsADrawingAndReturnsItsID() throws {
        let viewModel = makeViewModel()

        let id = try XCTUnwrap(viewModel.create())

        XCTAssertEqual(viewModel.drawings.map(\.id), [id])
        XCTAssertEqual(viewModel.drawings.first?.title, "Dibujo 1")
    }

    func testCreateReturnsNilAndShowsAnAlertWhenStorageFails() {
        let viewModel = makeViewModel()
        repository.error = .storageFailed

        XCTAssertNil(viewModel.create())
        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.storageFailed))
    }

    func testRenameUpdatesTheList() {
        let drawing = Drawing.sample(title: "Viejo")
        let viewModel = makeViewModel([drawing])
        viewModel.load()

        viewModel.rename(id: drawing.id, to: "Paisaje")

        XCTAssertEqual(viewModel.drawings.map(\.title), ["Paisaje"])
    }

    func testRenameWithABlankTitleShowsAnAlertAndKeepsTheOldTitle() {
        let drawing = Drawing.sample(title: "Viejo")
        let viewModel = makeViewModel([drawing])
        viewModel.load()

        viewModel.rename(id: drawing.id, to: "  ")

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.invalidTitle))
        XCTAssertEqual(viewModel.drawings.map(\.title), ["Viejo"])
    }

    func testDeleteRemovesTheDrawingFromTheList() {
        let kept = Drawing.sample(title: "Se queda")
        let removed = Drawing.sample(title: "Se va")
        let viewModel = makeViewModel([kept, removed])
        viewModel.load()

        viewModel.delete(id: removed.id)

        XCTAssertEqual(viewModel.drawings.map(\.title), ["Se queda"])
    }
}
