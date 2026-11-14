import XCTest
@testable import DrawPad

final class UseCasesTests: XCTestCase {
    func testLoadReturnsNilWhenNothingWasSaved() throws {
        let useCase = LoadDrawingUseCase(repository: InMemoryDrawingRepository())

        XCTAssertNil(try useCase.execute())
    }

    func testLoadReturnsStoredDrawing() throws {
        let drawing = Drawing(strokesData: Data("abc".utf8), updatedAt: Date(timeIntervalSince1970: 10))
        let useCase = LoadDrawingUseCase(repository: InMemoryDrawingRepository(stored: drawing))

        XCTAssertEqual(try useCase.execute(), drawing)
    }

    func testSaveStampsTheDrawingWithTheCurrentDate() throws {
        let repository = InMemoryDrawingRepository()
        let fixedDate = Date(timeIntervalSince1970: 1_000)
        let useCase = SaveDrawingUseCase(repository: repository, now: { fixedDate })

        try useCase.execute(strokesData: Data("abc".utf8))

        XCTAssertEqual(repository.stored, Drawing(strokesData: Data("abc".utf8), updatedAt: fixedDate))
    }

    func testSavePropagatesStorageErrors() {
        let repository = InMemoryDrawingRepository()
        repository.error = .storageFailed
        let useCase = SaveDrawingUseCase(repository: repository)

        XCTAssertThrowsError(try useCase.execute(strokesData: Data())) { error in
            XCTAssertEqual(error as? DrawingError, .storageFailed)
        }
    }

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
