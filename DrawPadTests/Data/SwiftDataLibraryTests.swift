import SwiftData
import XCTest
@testable import DrawPad

/// Prueba la biblioteca real contra una base de datos SwiftData en memoria.
final class SwiftDataLibraryTests: XCTestCase {
    private var container: ModelContainer!
    private var library: SwiftDataLibrary!

    override func setUpWithError() throws {
        container = try SwiftDataLibrary.makeContainer(inMemory: true)
        library = SwiftDataLibrary(container: container)
    }

    override func tearDown() {
        library = nil
        container = nil
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    // MARK: - Cuadernos

    func testANewDatabaseIsEmpty() throws {
        XCTAssertEqual(try library.listNotebooks(), [])
        XCTAssertNil(try library.findNotebook(id: UUID()))
        XCTAssertNil(try library.findDrawing(id: UUID()))
    }

    func testSaveThenFindReturnsTheSameNotebook() throws {
        let notebook = Notebook.sample(
            title: "Física", createdAt: date(5), cover: NotebookCover(color: .purple, style: .spine)
        )

        try library.save(notebook)

        XCTAssertEqual(try library.findNotebook(id: notebook.id), notebook)
    }

    func testSavingAnExistingNotebookRenamesIt() throws {
        var notebook = Notebook.sample(title: "Viejo")
        try library.save(notebook)

        notebook.title = "Nuevo"
        notebook.cover = NotebookCover(color: .orange, style: .plain)
        try library.save(notebook)

        XCTAssertEqual(try library.listNotebooks().map(\.title), ["Nuevo"])
        XCTAssertEqual(try library.findNotebook(id: notebook.id), notebook)
    }

    func testListNotebooksSummarizesPagesAndOrdersByLastActivity() throws {
        let quiet = Notebook.sample(title: "Quieto", createdAt: date(10))
        let active = Notebook.sample(title: "Activo", createdAt: date(1), cover: NotebookCover(color: .red, style: .plain))
        try library.save(quiet)
        try library.save(active)
        try library.save(Drawing.sample(notebookID: active.id, thumbnail: "portada", createdAt: date(1), updatedAt: date(2)))
        try library.save(Drawing.sample(notebookID: active.id, thumbnail: "otra", createdAt: date(3), updatedAt: date(99)))

        let summaries = try library.listNotebooks()

        XCTAssertEqual(summaries, [
            NotebookSummary(
                id: active.id, title: "Activo", cover: NotebookCover(color: .red, style: .plain),
                pageCount: 2, lastActivityAt: date(99)
            ),
            NotebookSummary(
                id: quiet.id, title: "Quieto", cover: .standard,
                pageCount: 0, lastActivityAt: date(10)
            ),
        ])
    }

    func testCoverColumnsThatAreEmptyOrUnknownAreReadAsTheStandardCover() throws {
        // Vacías: cuadernos guardados antes de que existieran las tapas.
        let empty = UUID()
        let unknown = UUID()
        let context = ModelContext(container)
        context.insert(NotebookRecord(
            id: empty, title: "Antiguo", createdAt: date(1), coverColorRaw: nil, coverStyleRaw: nil
        ))
        context.insert(NotebookRecord(
            id: unknown, title: "Raro", createdAt: date(2), coverColorRaw: "fucsia", coverStyleRaw: "anillas"
        ))
        try context.save()

        for id in [empty, unknown] {
            XCTAssertEqual(try library.findNotebook(id: id)?.cover, .standard)
        }
        XCTAssertEqual(try library.listNotebooks().map(\.cover), [.standard, .standard])
    }

    func testDeleteNotebookRemovesItsPagesButNotOthers() throws {
        let removed = Notebook.sample(title: "Se va")
        let kept = Notebook.sample(title: "Se queda")
        let removedPage = Drawing.sample(notebookID: removed.id)
        let keptPage = Drawing.sample(notebookID: kept.id)
        try library.save(removed)
        try library.save(kept)
        try library.save(removedPage)
        try library.save(keptPage)

        try library.deleteNotebook(id: removed.id)

        XCTAssertEqual(try library.listNotebooks().map(\.title), ["Se queda"])
        XCTAssertNil(try library.findDrawing(id: removedPage.id))
        XCTAssertEqual(try library.findDrawing(id: keptPage.id), keptPage)
    }

    func testDeletingAMissingNotebookDoesNothing() throws {
        XCTAssertNoThrow(try library.deleteNotebook(id: UUID()))
    }

    // MARK: - Hojas

    func testSaveThenFindReturnsTheSamePage() throws {
        let drawing = Drawing.sample(strokes: "trazos", thumbnail: "mini", background: .dots, theme: .dark)

        try library.save(drawing)

        XCTAssertEqual(try library.findDrawing(id: drawing.id), drawing)
    }

    func testSavingAnExistingPageReplacesIt() throws {
        var drawing = Drawing.sample(strokes: "viejo")
        try library.save(drawing)

        drawing.strokesData = Data("nuevo".utf8)
        drawing.updatedAt = date(200)
        drawing.background = .lines
        drawing.theme = .dark
        try library.save(drawing)

        XCTAssertEqual(try library.listDrawings(notebookID: drawing.notebookID).count, 1)
        XCTAssertEqual(try library.findDrawing(id: drawing.id), drawing)
    }

    func testListDrawingsReturnsOnlyThatNotebookInCreationOrder() throws {
        let notebookID = UUID()
        let first = Drawing.sample(notebookID: notebookID, createdAt: date(1))
        let second = Drawing.sample(notebookID: notebookID, thumbnail: "mini", createdAt: date(2))
        try library.save(second)
        try library.save(first)
        try library.save(Drawing.sample())

        XCTAssertEqual(try library.listDrawings(notebookID: notebookID), [first.summary, second.summary])
    }

    func testDeleteDrawingRemovesOnlyThatPage() throws {
        let notebookID = UUID()
        let kept = Drawing.sample(notebookID: notebookID, createdAt: date(1))
        let removed = Drawing.sample(notebookID: notebookID, createdAt: date(2))
        try library.save(kept)
        try library.save(removed)

        try library.deleteDrawing(id: removed.id)

        XCTAssertEqual(try library.listDrawings(notebookID: notebookID).map(\.id), [kept.id])
    }

    func testPaperColumnsThatAreEmptyOrUnknownAreReadAsBlankAndLight() throws {
        // Vacías: hojas guardadas antes de que existieran los fondos.
        let empty = UUID()
        let unknown = UUID()
        let notebookID = UUID()
        let context = ModelContext(container)
        context.insert(DrawingRecord(
            id: empty, strokesData: Data(), thumbnailData: nil, createdAt: date(1), updatedAt: date(1),
            backgroundRaw: nil, themeRaw: nil, notebookID: notebookID
        ))
        context.insert(DrawingRecord(
            id: unknown, strokesData: Data(), thumbnailData: nil, createdAt: date(2), updatedAt: date(2),
            backgroundRaw: "hexagonos", themeRaw: "sepia", notebookID: notebookID
        ))
        try context.save()

        for id in [empty, unknown] {
            let drawing = try XCTUnwrap(library.findDrawing(id: id))
            XCTAssertEqual(drawing.background, .blank)
            XCTAssertEqual(drawing.theme, .light)
        }
    }

    func testDataSurvivesANewLibraryOnTheSameDatabase() throws {
        let notebook = Notebook.sample(title: "Física")
        let drawing = Drawing.sample(notebookID: notebook.id, strokes: "trazos")
        try library.save(notebook)
        try library.save(drawing)

        let another = SwiftDataLibrary(container: container)

        XCTAssertEqual(try another.findNotebook(id: notebook.id), notebook)
        XCTAssertEqual(try another.findDrawing(id: drawing.id), drawing)
    }

    // MARK: - Migración de dibujos sin cuaderno

    /// Deja la base de datos como la de una versión anterior a los cuadernos.
    private func insertLegacyDrawing(id: UUID = UUID(), title: String, createdAt: Date) throws {
        let context = ModelContext(container)
        context.insert(DrawingRecord(
            id: id, title: title, strokesData: Data("trazos".utf8), thumbnailData: Data("mini".utf8),
            createdAt: createdAt, updatedAt: createdAt, backgroundRaw: "grid", themeRaw: nil, notebookID: nil
        ))
        try context.save()
    }

    func testAdoptOrphanDrawingsGivesEachOneANotebookWithItsTitle() throws {
        let gato = UUID()
        try insertLegacyDrawing(id: gato, title: "Gato", createdAt: date(1))
        try insertLegacyDrawing(title: "Casa", createdAt: date(2))
        let migrated = SwiftDataLibrary(container: container)

        try migrated.adoptOrphanDrawings()

        let notebooks = try migrated.listNotebooks()
        XCTAssertEqual(notebooks.map(\.title).sorted(), ["Casa", "Gato"])
        XCTAssertEqual(notebooks.map(\.pageCount), [1, 1])
        let page = try XCTUnwrap(migrated.findDrawing(id: gato))
        XCTAssertEqual(page.strokesData, Data("trazos".utf8))
        XCTAssertEqual(page.background, .grid)
        XCTAssertEqual(try migrated.findNotebook(id: page.notebookID)?.title, "Gato")
    }

    func testAdoptOrphanDrawingsDoesNothingTheSecondTime() throws {
        try insertLegacyDrawing(title: "Gato", createdAt: date(1))
        let migrated = SwiftDataLibrary(container: container)
        try migrated.adoptOrphanDrawings()

        try migrated.adoptOrphanDrawings()

        XCTAssertEqual(try migrated.listNotebooks().count, 1)
    }

    func testAdoptOrphanDrawingsLeavesPagesThatAlreadyHaveANotebook() throws {
        let notebook = Notebook.sample(title: "Física")
        let page = Drawing.sample(notebookID: notebook.id)
        try library.save(notebook)
        try library.save(page)

        try library.adoptOrphanDrawings()

        XCTAssertEqual(try library.listNotebooks().map(\.title), ["Física"])
        XCTAssertEqual(try library.findDrawing(id: page.id)?.notebookID, notebook.id)
    }

    func testAnOrphanWithoutTitleGetsAGenericNotebookName() throws {
        try insertLegacyDrawing(title: "", createdAt: date(1))
        let migrated = SwiftDataLibrary(container: container)

        try migrated.adoptOrphanDrawings()

        XCTAssertEqual(try migrated.listNotebooks().map(\.title), ["Cuaderno"])
    }
}
