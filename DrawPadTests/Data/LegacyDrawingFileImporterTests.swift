import XCTest
@testable import DrawPad

final class LegacyDrawingFileImporterTests: XCTestCase {
    private var fileURL: URL!

    override func setUp() {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DrawPadTests-\(UUID().uuidString).drawing")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testImportsTheOldFileAsADrawingAndDeletesIt() throws {
        try Data("trazos".utf8).write(to: fileURL)
        let repository = InMemoryDrawingRepository()
        let date = Date(timeIntervalSince1970: 50)

        LegacyDrawingFileImporter(fileURL: fileURL).importIfNeeded(into: repository, now: date)

        let imported = try XCTUnwrap(repository.drawings.values.first)
        XCTAssertEqual(imported.title, LegacyDrawingFileImporter.importedTitle)
        XCTAssertEqual(imported.strokesData, Data("trazos".utf8))
        XCTAssertEqual(imported.updatedAt, date)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testDoesNothingWhenThereIsNoOldFile() {
        let repository = InMemoryDrawingRepository()

        LegacyDrawingFileImporter(fileURL: fileURL).importIfNeeded(into: repository)

        XCTAssertTrue(repository.drawings.isEmpty)
    }

    func testKeepsTheOldFileWhenSavingFails() throws {
        try Data("trazos".utf8).write(to: fileURL)
        let repository = InMemoryDrawingRepository()
        repository.error = .storageFailed

        LegacyDrawingFileImporter(fileURL: fileURL).importIfNeeded(into: repository)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
}
