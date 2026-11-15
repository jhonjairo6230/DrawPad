import XCTest
@testable import DrawPad

final class UseCasesTests: XCTestCase {
    // MARK: - Listar

    func testListReturnsSummariesNewestFirst() throws {
        let old = Drawing.sample(title: "Viejo", updatedAt: Date(timeIntervalSince1970: 1))
        let new = Drawing.sample(title: "Nuevo", updatedAt: Date(timeIntervalSince1970: 2))
        let useCase = ListDrawingsUseCase(repository: InMemoryDrawingRepository([old, new]))

        XCTAssertEqual(try useCase.execute().map(\.title), ["Nuevo", "Viejo"])
    }

    // MARK: - Crear

    func testCreateSavesAnEmptyDrawingWithANumberedTitle() throws {
        let repository = InMemoryDrawingRepository([.sample(), .sample()])
        let id = UUID()
        let date = Date(timeIntervalSince1970: 500)
        let useCase = CreateDrawingUseCase(repository: repository, now: { date }, makeID: { id })

        let created = try useCase.execute()

        let expected = Drawing(
            id: id, title: "Dibujo 3", strokesData: Data(), thumbnailData: nil, createdAt: date, updatedAt: date
        )
        XCTAssertEqual(created, expected)
        XCTAssertEqual(repository.drawings[id], expected)
    }

    // MARK: - Cargar

    func testLoadReturnsTheDrawing() throws {
        let drawing = Drawing.sample(strokes: "abc")
        let useCase = LoadDrawingUseCase(repository: InMemoryDrawingRepository([drawing]))

        XCTAssertEqual(try useCase.execute(id: drawing.id), drawing)
    }

    func testLoadFailsWhenTheDrawingDoesNotExist() {
        let useCase = LoadDrawingUseCase(repository: InMemoryDrawingRepository())

        XCTAssertThrowsError(try useCase.execute(id: UUID())) { error in
            XCTAssertEqual(error as? DrawingError, .drawingNotFound)
        }
    }

    // MARK: - Guardar

    func testSaveUpdatesStrokesThumbnailAndDateButKeepsTheRest() throws {
        let drawing = Drawing.sample(title: "Gato", strokes: "viejo")
        let repository = InMemoryDrawingRepository([drawing])
        let date = Date(timeIntervalSince1970: 1_000)
        let useCase = SaveDrawingUseCase(repository: repository, now: { date })

        try useCase.execute(id: drawing.id, strokesData: Data("nuevo".utf8), thumbnailData: Data("mini".utf8))

        var expected = drawing
        expected.strokesData = Data("nuevo".utf8)
        expected.thumbnailData = Data("mini".utf8)
        expected.updatedAt = date
        XCTAssertEqual(repository.drawings[drawing.id], expected)
    }

    func testSaveFailsWhenTheDrawingWasDeleted() {
        let useCase = SaveDrawingUseCase(repository: InMemoryDrawingRepository())

        XCTAssertThrowsError(try useCase.execute(id: UUID(), strokesData: Data(), thumbnailData: nil)) { error in
            XCTAssertEqual(error as? DrawingError, .drawingNotFound)
        }
    }

    func testSavePropagatesStorageErrors() {
        let repository = InMemoryDrawingRepository()
        repository.error = .storageFailed
        let useCase = SaveDrawingUseCase(repository: repository)

        XCTAssertThrowsError(try useCase.execute(id: UUID(), strokesData: Data(), thumbnailData: nil)) { error in
            XCTAssertEqual(error as? DrawingError, .storageFailed)
        }
    }

    // MARK: - Renombrar

    func testRenameTrimsTheTitleAndKeepsTheDate() throws {
        let drawing = Drawing.sample(title: "Viejo")
        let repository = InMemoryDrawingRepository([drawing])
        let useCase = RenameDrawingUseCase(repository: repository)

        try useCase.execute(id: drawing.id, title: "  Paisaje \n")

        XCTAssertEqual(repository.drawings[drawing.id]?.title, "Paisaje")
        XCTAssertEqual(repository.drawings[drawing.id]?.updatedAt, drawing.updatedAt)
    }

    func testRenameRejectsABlankTitle() {
        let drawing = Drawing.sample(title: "Viejo")
        let repository = InMemoryDrawingRepository([drawing])
        let useCase = RenameDrawingUseCase(repository: repository)

        XCTAssertThrowsError(try useCase.execute(id: drawing.id, title: "   ")) { error in
            XCTAssertEqual(error as? DrawingError, .invalidTitle)
        }
        XCTAssertEqual(repository.drawings[drawing.id]?.title, "Viejo")
    }

    func testRenameFailsWhenTheDrawingDoesNotExist() {
        let useCase = RenameDrawingUseCase(repository: InMemoryDrawingRepository())

        XCTAssertThrowsError(try useCase.execute(id: UUID(), title: "Algo")) { error in
            XCTAssertEqual(error as? DrawingError, .drawingNotFound)
        }
    }

    // MARK: - Eliminar

    func testDeleteRemovesTheDrawing() throws {
        let drawing = Drawing.sample()
        let repository = InMemoryDrawingRepository([drawing])
        let useCase = DeleteDrawingUseCase(repository: repository)

        try useCase.execute(id: drawing.id)

        XCTAssertTrue(repository.drawings.isEmpty)
    }

    // MARK: - Exportar

    func testExportAddsThePNGToTheLibrary() async throws {
        let library = SpyImageLibrary()
        let useCase = ExportDrawingUseCase(library: library)

        try await useCase.execute(pngData: Data("png".utf8))

        XCTAssertEqual(library.added, [Data("png".utf8)])
    }

    func testExportRejectsAnEmptyImage() async {
        let library = SpyImageLibrary()
        let useCase = ExportDrawingUseCase(library: library)

        do {
            try await useCase.execute(pngData: Data())
            XCTFail("Debía lanzar emptyDrawing")
        } catch {
            XCTAssertEqual(error as? DrawingError, .emptyDrawing)
        }
        XCTAssertTrue(library.added.isEmpty)
    }
}
