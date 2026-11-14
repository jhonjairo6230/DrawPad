import XCTest
@testable import DrawPad

final class FileDrawingRepositoryTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DrawPadTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testLoadReturnsNilWhenTheFileDoesNotExist() throws {
        let repository = FileDrawingRepository(directory: directory)

        XCTAssertNil(try repository.load())
    }

    func testSaveThenLoadReturnsTheSameDrawing() throws {
        let repository = FileDrawingRepository(directory: directory)
        let drawing = Drawing(strokesData: Data("trazos".utf8), updatedAt: Date(timeIntervalSince1970: 1_700_000_000))

        try repository.save(drawing)

        XCTAssertEqual(try repository.load(), drawing)
    }

    func testSaveReplacesThePreviousDrawing() throws {
        let repository = FileDrawingRepository(directory: directory)
        try repository.save(Drawing(strokesData: Data("viejo".utf8), updatedAt: Date(timeIntervalSince1970: 1)))

        try repository.save(Drawing(strokesData: Data("nuevo".utf8), updatedAt: Date(timeIntervalSince1970: 2)))

        XCTAssertEqual(try repository.load()?.strokesData, Data("nuevo".utf8))
    }

    func testSaveFailsWithStorageErrorWhenTheDirectoryCannotBeCreated() throws {
        // Un archivo ocupa el lugar donde debería ir la carpeta.
        let blocker = FileManager.default.temporaryDirectory
            .appendingPathComponent("DrawPadTests-blocker-\(UUID().uuidString)")
        try Data().write(to: blocker)
        defer { try? FileManager.default.removeItem(at: blocker) }
        let repository = FileDrawingRepository(directory: blocker.appendingPathComponent("sub"))

        XCTAssertThrowsError(try repository.save(Drawing(strokesData: Data(), updatedAt: Date()))) { error in
            XCTAssertEqual(error as? DrawingError, .storageFailed)
        }
    }
}
