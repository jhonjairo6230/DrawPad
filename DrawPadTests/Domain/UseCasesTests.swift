import XCTest
@testable import DrawPad

final class UseCasesTests: XCTestCase {
    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    // MARK: - Cuadernos: listar

    func testListNotebooksOrdersByLastActivity() throws {
        let old = Notebook.sample(title: "Antiguo", createdAt: date(1))
        let recent = Notebook.sample(title: "Reciente", createdAt: date(2))
        let touched = Notebook.sample(title: "Con hoja nueva", createdAt: date(0))
        let library = InMemoryLibrary(
            notebooks: [old, recent, touched],
            drawings: [.sample(notebookID: touched.id, updatedAt: date(50))]
        )

        let titles = try ListNotebooksUseCase(notebooks: library).execute().map(\.title)

        XCTAssertEqual(titles, ["Con hoja nueva", "Reciente", "Antiguo"])
    }

    func testListNotebooksIncludesPageCountAndCover() throws {
        let cover = NotebookCover(color: .red, style: .spine)
        let notebook = Notebook.sample(cover: cover)
        let library = InMemoryLibrary(notebooks: [notebook], drawings: [
            .sample(notebookID: notebook.id, createdAt: date(1)),
            .sample(notebookID: notebook.id, createdAt: date(2)),
        ])

        let summary = try XCTUnwrap(ListNotebooksUseCase(notebooks: library).execute().first)

        XCTAssertEqual(summary.pageCount, 2)
        XCTAssertEqual(summary.cover, cover)
    }

    // MARK: - Cuadernos: crear

    func testCreateNotebookSavesItWithANumberedTitleAndOneBlankPage() throws {
        let library = InMemoryLibrary(notebooks: [.sample(), .sample()])
        let now = date(500)
        let useCase = CreateNotebookUseCase(notebooks: library, drawings: library, now: { now })

        let notebook = try useCase.execute()

        XCTAssertEqual(notebook.title, "Cuaderno 3")
        XCTAssertEqual(notebook.createdAt, now)
        XCTAssertEqual(library.notebooks[notebook.id], notebook)
        let pages = library.drawings.values.filter { $0.notebookID == notebook.id }
        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages.first?.strokesData, Data())
        XCTAssertEqual(pages.first?.background, .blank)
    }

    func testEachNewNotebookGetsTheNextCoverColor() throws {
        let library = InMemoryLibrary()
        let useCase = CreateNotebookUseCase(notebooks: library, drawings: library)
        let colors = CoverColor.allCases

        let created = try (0...colors.count).map { _ in try useCase.execute() }

        XCTAssertEqual(created.prefix(colors.count).map(\.cover.color), colors)
        // Agotada la lista, vuelve a empezar.
        XCTAssertEqual(created.last?.cover.color, colors.first)
        XCTAssertEqual(Set(created.map(\.cover.style)), [NotebookCover.standard.style])
    }

    // MARK: - Cuadernos: portada

    func testChangeCoverKeepsTitleAndPages() throws {
        let notebook = Notebook.sample(title: "Física")
        let page = Drawing.sample(notebookID: notebook.id)
        let library = InMemoryLibrary(notebooks: [notebook], drawings: [page])
        let cover = NotebookCover(color: .green, style: .plain)

        try ChangeCoverUseCase(notebooks: library).execute(id: notebook.id, cover: cover)

        var expected = notebook
        expected.cover = cover
        XCTAssertEqual(library.notebooks[notebook.id], expected)
        XCTAssertEqual(library.drawings[page.id], page)
    }

    func testChangeCoverFailsWhenTheNotebookDoesNotExist() {
        let useCase = ChangeCoverUseCase(notebooks: InMemoryLibrary())

        XCTAssertThrowsError(try useCase.execute(id: UUID(), cover: .standard)) { error in
            XCTAssertEqual(error as? DrawingError, .notebookNotFound)
        }
    }

    // MARK: - Cuadernos: cargar, renombrar, eliminar

    func testLoadNotebookReturnsIt() throws {
        let notebook = Notebook.sample(title: "Apuntes")
        let library = InMemoryLibrary(notebooks: [notebook])

        XCTAssertEqual(try LoadNotebookUseCase(notebooks: library).execute(id: notebook.id), notebook)
    }

    func testLoadNotebookFailsWhenItDoesNotExist() {
        let useCase = LoadNotebookUseCase(notebooks: InMemoryLibrary())

        XCTAssertThrowsError(try useCase.execute(id: UUID())) { error in
            XCTAssertEqual(error as? DrawingError, .notebookNotFound)
        }
    }

    func testRenameNotebookTrimsTheTitle() throws {
        let notebook = Notebook.sample(title: "Viejo")
        let library = InMemoryLibrary(notebooks: [notebook])

        try RenameNotebookUseCase(notebooks: library).execute(id: notebook.id, title: "  Física \n")

        XCTAssertEqual(library.notebooks[notebook.id]?.title, "Física")
    }

    func testRenameNotebookRejectsABlankTitle() {
        let notebook = Notebook.sample(title: "Viejo")
        let library = InMemoryLibrary(notebooks: [notebook])
        let useCase = RenameNotebookUseCase(notebooks: library)

        XCTAssertThrowsError(try useCase.execute(id: notebook.id, title: "   ")) { error in
            XCTAssertEqual(error as? DrawingError, .invalidTitle)
        }
        XCTAssertEqual(library.notebooks[notebook.id]?.title, "Viejo")
    }

    func testRenameNotebookFailsWhenItDoesNotExist() {
        let useCase = RenameNotebookUseCase(notebooks: InMemoryLibrary())

        XCTAssertThrowsError(try useCase.execute(id: UUID(), title: "Algo")) { error in
            XCTAssertEqual(error as? DrawingError, .notebookNotFound)
        }
    }

    func testDeleteNotebookRemovesItAndItsPages() throws {
        let removed = Notebook.sample(title: "Se va")
        let kept = Notebook.sample(title: "Se queda")
        let keptPage = Drawing.sample(notebookID: kept.id)
        let library = InMemoryLibrary(notebooks: [removed, kept], drawings: [
            .sample(notebookID: removed.id), .sample(notebookID: removed.id), keptPage,
        ])

        try DeleteNotebookUseCase(notebooks: library).execute(id: removed.id)

        XCTAssertEqual(Array(library.notebooks.keys), [kept.id])
        XCTAssertEqual(Array(library.drawings.keys), [keptPage.id])
    }

    // MARK: - Hojas: listar, añadir, eliminar

    func testListPagesReturnsThemInCreationOrder() throws {
        let notebookID = UUID()
        let first = Drawing.sample(notebookID: notebookID, createdAt: date(1))
        let second = Drawing.sample(notebookID: notebookID, createdAt: date(2))
        let library = InMemoryLibrary(drawings: [second, first, .sample()])

        let pages = try ListPagesUseCase(drawings: library).execute(notebookID: notebookID)

        XCTAssertEqual(pages.map(\.id), [first.id, second.id])
    }

    func testAddPageAppendsABlankPageWithThePaperOfTheLastOne() throws {
        let notebookID = UUID()
        let library = InMemoryLibrary(drawings: [
            .sample(notebookID: notebookID, createdAt: date(1), background: .blank, theme: .light),
            .sample(notebookID: notebookID, strokes: "algo", createdAt: date(2), background: .grid, theme: .dark),
        ])
        let now = date(10)

        let page = try AddPageUseCase(drawings: library, now: { now }).execute(notebookID: notebookID)

        XCTAssertEqual(page.notebookID, notebookID)
        XCTAssertEqual(page.strokesData, Data())
        XCTAssertEqual(page.background, .grid)
        XCTAssertEqual(page.theme, .dark)
        XCTAssertEqual(page.createdAt, now)
        XCTAssertEqual(try library.listDrawings(notebookID: notebookID).last?.id, page.id)
    }

    func testAddPageToANotebookWithoutPagesUsesBlankLightPaper() throws {
        let library = InMemoryLibrary()

        let page = try AddPageUseCase(drawings: library).execute(notebookID: UUID())

        XCTAssertEqual(page.background, .blank)
        XCTAssertEqual(page.theme, .light)
    }

    func testDeletePageRemovesOnlyThatPage() throws {
        let notebookID = UUID()
        let kept = Drawing.sample(notebookID: notebookID, createdAt: date(1))
        let removed = Drawing.sample(notebookID: notebookID, createdAt: date(2))
        let library = InMemoryLibrary(drawings: [kept, removed])

        try DeletePageUseCase(drawings: library).execute(id: removed.id)

        XCTAssertEqual(Array(library.drawings.keys), [kept.id])
    }

    func testDeletePageRefusesToRemoveTheLastPage() {
        let page = Drawing.sample()
        let library = InMemoryLibrary(drawings: [page])

        XCTAssertThrowsError(try DeletePageUseCase(drawings: library).execute(id: page.id)) { error in
            XCTAssertEqual(error as? DrawingError, .lastPage)
        }
        XCTAssertNotNil(library.drawings[page.id])
    }

    func testDeletePageFailsWhenItDoesNotExist() {
        let useCase = DeletePageUseCase(drawings: InMemoryLibrary())

        XCTAssertThrowsError(try useCase.execute(id: UUID())) { error in
            XCTAssertEqual(error as? DrawingError, .drawingNotFound)
        }
    }

    // MARK: - Hojas: cargar y guardar

    func testLoadReturnsThePage() throws {
        let drawing = Drawing.sample(strokes: "abc")
        let useCase = LoadDrawingUseCase(repository: InMemoryLibrary(drawings: [drawing]))

        XCTAssertEqual(try useCase.execute(id: drawing.id), drawing)
    }

    func testLoadFailsWhenThePageDoesNotExist() {
        let useCase = LoadDrawingUseCase(repository: InMemoryLibrary())

        XCTAssertThrowsError(try useCase.execute(id: UUID())) { error in
            XCTAssertEqual(error as? DrawingError, .drawingNotFound)
        }
    }

    func testSaveUpdatesStrokesThumbnailAndDateButKeepsTheRest() throws {
        let drawing = Drawing.sample(strokes: "viejo", background: .dots)
        let library = InMemoryLibrary(drawings: [drawing])
        let now = date(1_000)
        let useCase = SaveDrawingUseCase(repository: library, now: { now })

        try useCase.execute(id: drawing.id, strokesData: Data("nuevo".utf8), thumbnailData: Data("mini".utf8))

        var expected = drawing
        expected.strokesData = Data("nuevo".utf8)
        expected.thumbnailData = Data("mini".utf8)
        expected.updatedAt = now
        XCTAssertEqual(library.drawings[drawing.id], expected)
    }

    func testSaveFailsWhenThePageWasDeleted() {
        let useCase = SaveDrawingUseCase(repository: InMemoryLibrary())

        XCTAssertThrowsError(try useCase.execute(id: UUID(), strokesData: Data(), thumbnailData: nil)) { error in
            XCTAssertEqual(error as? DrawingError, .drawingNotFound)
        }
    }

    func testSavePropagatesStorageErrors() {
        let library = InMemoryLibrary()
        library.error = .storageFailed
        let useCase = SaveDrawingUseCase(repository: library)

        XCTAssertThrowsError(try useCase.execute(id: UUID(), strokesData: Data(), thumbnailData: nil)) { error in
            XCTAssertEqual(error as? DrawingError, .storageFailed)
        }
    }

    // MARK: - Cambiar el papel

    func testChangeBackgroundKeepsStrokesAndDate() throws {
        let drawing = Drawing.sample(strokes: "trazos")
        let library = InMemoryLibrary(drawings: [drawing])

        try ChangeBackgroundUseCase(repository: library).execute(id: drawing.id, background: .grid, theme: .dark)

        var expected = drawing
        expected.background = .grid
        expected.theme = .dark
        XCTAssertEqual(library.drawings[drawing.id], expected)
    }

    func testChangeBackgroundFailsWhenThePageDoesNotExist() {
        let useCase = ChangeBackgroundUseCase(repository: InMemoryLibrary())

        XCTAssertThrowsError(try useCase.execute(id: UUID(), background: .dots, theme: .light)) { error in
            XCTAssertEqual(error as? DrawingError, .drawingNotFound)
        }
    }

    // MARK: - Compartir

    func testPrepareShareFileNamesTheFileAfterThePage() throws {
        let store = SpyExportFileStore()
        let useCase = PrepareShareFileUseCase(store: store)

        let url = try useCase.execute(name: "Física - Hoja 2", format: .pdf, data: Data("pdf".utf8))

        XCTAssertEqual(url.lastPathComponent, "Física - Hoja 2.pdf")
        XCTAssertEqual(store.written.map(\.fileName), ["Física - Hoja 2.pdf"])
        XCTAssertEqual(store.written.first?.data, Data("pdf".utf8))
    }

    func testPrepareShareFileRejectsEmptyData() {
        let store = SpyExportFileStore()
        let useCase = PrepareShareFileUseCase(store: store)

        XCTAssertThrowsError(try useCase.execute(name: "Gato", format: .png, data: Data())) { error in
            XCTAssertEqual(error as? DrawingError, .emptyDrawing)
        }
        XCTAssertTrue(store.written.isEmpty)
    }

    func testSafeFileNameReplacesForbiddenCharacters() {
        XCTAssertEqual(PrepareShareFileUseCase.safeFileName(from: "Plano: casa/jardín"), "Plano- casa-jardín")
        XCTAssertEqual(PrepareShareFileUseCase.safeFileName(from: "  ...  "), "Dibujo")
        XCTAssertEqual(PrepareShareFileUseCase.safeFileName(from: ""), "Dibujo")
        XCTAssertEqual(PrepareShareFileUseCase.safeFileName(from: "Línea 1\nLínea 2"), "Línea 1-Línea 2")
    }

    // MARK: - Exportar a Fotos

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
