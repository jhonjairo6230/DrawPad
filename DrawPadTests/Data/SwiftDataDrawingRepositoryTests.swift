import SwiftData
import XCTest
@testable import DrawPad

/// Prueba el repositorio real contra una base de datos SwiftData en memoria.
final class SwiftDataDrawingRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var repository: SwiftDataDrawingRepository!

    override func setUpWithError() throws {
        container = try SwiftDataDrawingRepository.makeContainer(inMemory: true)
        repository = SwiftDataDrawingRepository(container: container)
    }

    override func tearDown() {
        repository = nil
        container = nil
    }

    func testANewDatabaseIsEmpty() throws {
        XCTAssertEqual(try repository.list(), [])
        XCTAssertNil(try repository.find(id: UUID()))
    }

    func testSaveThenFindReturnsTheSameDrawing() throws {
        let drawing = Drawing.sample(title: "Gato", strokes: "trazos", thumbnail: "mini")

        try repository.save(drawing)

        XCTAssertEqual(try repository.find(id: drawing.id), drawing)
    }

    func testSaveWithAnExistingIDReplacesTheDrawing() throws {
        var drawing = Drawing.sample(title: "Viejo", strokes: "viejo")
        try repository.save(drawing)

        drawing.title = "Nuevo"
        drawing.strokesData = Data("nuevo".utf8)
        drawing.updatedAt = Date(timeIntervalSince1970: 200)
        try repository.save(drawing)

        XCTAssertEqual(try repository.list().count, 1)
        XCTAssertEqual(try repository.find(id: drawing.id), drawing)
    }

    func testListReturnsSummariesNewestFirst() throws {
        let old = Drawing.sample(title: "Viejo", updatedAt: Date(timeIntervalSince1970: 1))
        let new = Drawing.sample(title: "Nuevo", thumbnail: "mini", updatedAt: Date(timeIntervalSince1970: 2))
        try repository.save(old)
        try repository.save(new)

        XCTAssertEqual(try repository.list(), [new.summary, old.summary])
    }

    func testDeleteRemovesOnlyThatDrawing() throws {
        let kept = Drawing.sample(title: "Se queda")
        let removed = Drawing.sample(title: "Se va")
        try repository.save(kept)
        try repository.save(removed)

        try repository.delete(id: removed.id)

        XCTAssertEqual(try repository.list().map(\.title), ["Se queda"])
    }

    func testDeletingAMissingDrawingDoesNothing() throws {
        XCTAssertNoThrow(try repository.delete(id: UUID()))
    }

    func testDataSurvivesANewRepositoryOnTheSameDatabase() throws {
        let drawing = Drawing.sample(strokes: "trazos")
        try repository.save(drawing)

        let another = SwiftDataDrawingRepository(container: container)

        XCTAssertEqual(try another.find(id: drawing.id), drawing)
    }
}
