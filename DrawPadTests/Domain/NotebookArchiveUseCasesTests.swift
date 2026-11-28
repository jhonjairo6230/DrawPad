import XCTest
@testable import DrawPad

final class NotebookArchiveUseCasesTests: XCTestCase {
    private var library: InMemoryLibrary!
    private var coder: InMemoryArchiveCoder!
    private var reader: FakeFileReader!
    private var store: SpyExportFileStore!
    private let fileURL = URL(fileURLWithPath: "/tmp/Física.drawpad")

    override func setUp() {
        library = InMemoryLibrary()
        coder = InMemoryArchiveCoder()
        reader = FakeFileReader()
        store = SpyExportFileStore()
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    private func makeExport() -> ExportNotebookUseCase {
        ExportNotebookUseCase(notebooks: library, drawings: library, elements: library, coder: coder, store: store)
    }

    private func makeImport() -> ImportNotebookUseCase {
        ImportNotebookUseCase(notebooks: library, drawings: library, elements: library, coder: coder, reader: reader)
    }

    /// Un cuaderno "Física" con dos hojas, un texto en la primera y una figura
    /// unida a otra en la segunda.
    private func sampleBundle(title: String = "Física") -> NotebookBundle {
        let notebook = Notebook.sample(title: title, cover: NotebookCover(color: .red, style: .spine))
        let first = Drawing.sample(notebookID: notebook.id, strokes: "uno", createdAt: date(1))
        let second = Drawing.sample(notebookID: notebook.id, strokes: "dos", createdAt: date(2), background: .grid)
        let a = PageElement.sampleShape(pageID: second.id, .rectangle, label: "API", createdAt: date(1))
        let b = PageElement.sampleShape(pageID: second.id, .cylinder, label: "DB", createdAt: date(2))
        return NotebookBundle(
            notebook: notebook,
            pages: [first, second],
            elements: [
                .sampleText(pageID: first.id, "Hola", createdAt: date(1)),
                a, b,
                .sampleConnector(pageID: second.id, from: a.id, to: b.id, createdAt: date(3)),
            ]
        )
    }

    private func store(_ bundle: NotebookBundle) throws {
        try library.save(bundle.notebook)
        for page in bundle.pages { try library.save(page) }
        for element in bundle.elements { try library.save(element) }
    }

    // MARK: - Exportar

    func testExportWritesTheWholeNotebookInPageOrder() throws {
        let bundle = sampleBundle()
        try store(bundle)

        let url = try makeExport().execute(id: bundle.notebook.id)

        XCTAssertEqual(url.lastPathComponent, "Física.drawpad")
        XCTAssertEqual(store.written.map(\.fileName), ["Física.drawpad"])
        let exported = try XCTUnwrap(coder.encoded.first)
        XCTAssertEqual(exported.notebook, bundle.notebook)
        XCTAssertEqual(exported.pages, bundle.pages)
        XCTAssertEqual(Set(exported.elements.map(\.id)), Set(bundle.elements.map(\.id)))
    }

    func testExportingAMissingNotebookFails() {
        XCTAssertThrowsError(try makeExport().execute(id: UUID())) { error in
            XCTAssertEqual(error as? DrawingError, .notebookNotFound)
        }
        XCTAssertTrue(store.written.isEmpty)
    }

    // MARK: - Importar

    func testImportingANewNotebookSavesEverything() throws {
        let bundle = sampleBundle()
        coder.decodeResult = .success(bundle)

        let result = try makeImport().execute(fileURL: fileURL)

        XCTAssertEqual(result, NotebookImportResult(notebook: bundle.notebook, replacedExisting: false))
        XCTAssertEqual(reader.readURLs, [fileURL])
        XCTAssertEqual(library.notebooks[bundle.notebook.id], bundle.notebook)
        XCTAssertEqual(try library.listDrawings(notebookID: bundle.notebook.id).map(\.id), bundle.pages.map(\.id))
        XCTAssertEqual(library.elements.count, bundle.elements.count)
    }

    func testImportingANotebookThatIsAlreadyHereReplacesIt() throws {
        let old = sampleBundle(title: "Física")
        let other = sampleBundle(title: "Química")
        try store(old)
        try store(other)
        // La versión nueva: el mismo cuaderno, renombrado y con una sola hoja.
        let newPage = Drawing.sample(notebookID: old.notebook.id, strokes: "nueva")
        var renamed = old.notebook
        renamed.title = "Física II"
        coder.decodeResult = .success(NotebookBundle(notebook: renamed, pages: [newPage], elements: []))

        let result = try makeImport().execute(fileURL: fileURL)

        XCTAssertTrue(result.replacedExisting)
        XCTAssertEqual(library.notebooks[old.notebook.id]?.title, "Física II")
        XCTAssertEqual(try library.listDrawings(notebookID: old.notebook.id).map(\.id), [newPage.id])
        for page in old.pages {
            XCTAssertNil(library.drawings[page.id])
            XCTAssertEqual(try library.listElements(pageID: page.id), [])
        }
        // El otro cuaderno sigue igual.
        XCTAssertEqual(library.notebooks[other.notebook.id], other.notebook)
        XCTAssertEqual(try library.listDrawings(notebookID: other.notebook.id).count, 2)
    }

    func testAnInconsistentFileIsRejectedWithoutTouchingAnything() throws {
        let existing = sampleBundle()
        try store(existing)
        let foreignElement = PageElement.sampleText(pageID: UUID())
        let broken = [
            NotebookBundle(notebook: existing.notebook, pages: [], elements: []),
            NotebookBundle(notebook: existing.notebook, pages: existing.pages, elements: [foreignElement]),
            NotebookBundle(notebook: existing.notebook, pages: [Drawing.sample()], elements: []),
        ]

        for bundle in broken {
            coder.decodeResult = .success(bundle)
            XCTAssertThrowsError(try makeImport().execute(fileURL: fileURL)) { error in
                XCTAssertEqual(error as? DrawingError, .importFailed)
            }
        }
        XCTAssertEqual(try library.listDrawings(notebookID: existing.notebook.id).count, 2)
    }

    func testReadingAndFormatErrorsAreReported() {
        reader.error = .importFailed
        XCTAssertThrowsError(try makeImport().execute(fileURL: fileURL)) { error in
            XCTAssertEqual(error as? DrawingError, .importFailed)
        }

        reader.error = nil
        coder.decodeResult = .failure(.unsupportedArchiveVersion)
        XCTAssertThrowsError(try makeImport().execute(fileURL: fileURL)) { error in
            XCTAssertEqual(error as? DrawingError, .unsupportedArchiveVersion)
        }
        XCTAssertTrue(library.notebooks.isEmpty)
    }

    func testBundleConsistency() {
        let bundle = sampleBundle()
        XCTAssertTrue(bundle.isConsistent)

        let duplicatedPage = NotebookBundle(
            notebook: bundle.notebook, pages: [bundle.pages[0], bundle.pages[0]], elements: []
        )
        XCTAssertFalse(duplicatedPage.isConsistent)
    }
}
