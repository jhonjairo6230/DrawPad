import XCTest
@testable import DrawPad

final class TemporaryExportFileStoreTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DrawPadTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
    }

    func testWritesTheFileWithItsName() throws {
        let store = TemporaryExportFileStore(directory: directory)

        let url = try store.write(Data("pdf".utf8), fileName: "Gato.pdf")

        XCTAssertEqual(url.lastPathComponent, "Gato.pdf")
        XCTAssertEqual(try Data(contentsOf: url), Data("pdf".utf8))
    }

    func testEachWriteRemovesPreviousExports() throws {
        let store = TemporaryExportFileStore(directory: directory)
        let old = try store.write(Data("uno".utf8), fileName: "Uno.png")

        _ = try store.write(Data("dos".utf8), fileName: "Dos.png")

        XCTAssertFalse(FileManager.default.fileExists(atPath: old.path))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["Dos.png"])
    }

    func testFailsWithShareFailedWhenTheFolderCannotBeCreated() throws {
        // Un archivo ocupa el lugar del padre de la carpeta.
        let blocker = FileManager.default.temporaryDirectory
            .appendingPathComponent("DrawPadTests-blocker-\(UUID().uuidString)")
        try Data().write(to: blocker)
        defer { try? FileManager.default.removeItem(at: blocker) }
        let store = TemporaryExportFileStore(directory: blocker.appendingPathComponent("Exports"))

        XCTAssertThrowsError(try store.write(Data("x".utf8), fileName: "X.png")) { error in
            XCTAssertEqual(error as? DrawingError, .shareFailed)
        }
    }
}
