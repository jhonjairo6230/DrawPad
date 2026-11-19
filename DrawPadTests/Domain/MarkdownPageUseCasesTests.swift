import XCTest
@testable import DrawPad

final class MarkdownPageUseCasesTests: XCTestCase {
    private let notebookID = UUID()
    private var library: InMemoryLibrary!

    override func setUp() {
        library = InMemoryLibrary()
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    // MARK: - Crear

    func testAddingAMarkdownPagePutsItLastWithTheTemplate() throws {
        try library.save(Drawing.sample(notebookID: notebookID, createdAt: date(1)))
        let useCase = AddMarkdownPageUseCase(drawings: library, now: { Date(timeIntervalSince1970: 10) })

        let page = try useCase.execute(notebookID: notebookID)

        XCTAssertEqual(page.kind, .markdown)
        XCTAssertEqual(page.markdown, AddMarkdownPageUseCase.template)
        XCTAssertEqual(page.strokesData, Data())
        XCTAssertEqual(try library.listDrawings(notebookID: notebookID).map(\.kind), [.drawing, .markdown])
    }

    func testTheTemplateIsASpecWithAMermaidBlockAndTasks() {
        let template = AddMarkdownPageUseCase.template

        XCTAssertTrue(template.hasPrefix("# "))
        XCTAssertTrue(template.contains("```mermaid"))
        XCTAssertTrue(template.contains("- [ ]"))
    }

    // MARK: - Guardar

    func testSavingKeepsTheTextExactlyAndUpdatesTheDate() throws {
        let page = Drawing.sample(notebookID: notebookID, kind: .markdown, markdown: "# Viejo")
        try library.save(page)
        let useCase = SaveMarkdownUseCase(drawings: library, now: { Date(timeIntervalSince1970: 99) })

        try useCase.execute(id: page.id, markdown: "  # Nuevo\n\n- uno  \n")

        XCTAssertEqual(library.drawings[page.id]?.markdown, "  # Nuevo\n\n- uno  \n")
        XCTAssertEqual(library.drawings[page.id]?.updatedAt, date(99))
        XCTAssertEqual(library.drawings[page.id]?.kind, .markdown)
    }

    func testMarkdownCannotBeSavedOnADrawingPage() throws {
        let page = Drawing.sample(notebookID: notebookID)
        try library.save(page)

        XCTAssertThrowsError(try SaveMarkdownUseCase(drawings: library).execute(id: page.id, markdown: "# X")) {
            XCTAssertEqual($0 as? DrawingError, .drawingNotFound)
        }
        XCTAssertEqual(library.drawings[page.id]?.markdown, "")
    }

    // MARK: - Importar

    func testImportingAFileAddsItsTextAsAPage() throws {
        let reader = FakeFileReader()
        reader.data = Data("# README\n\nHola".utf8)
        let useCase = ImportMarkdownPageUseCase(reader: reader, addPage: AddMarkdownPageUseCase(drawings: library))

        let page = try useCase.execute(notebookID: notebookID, fileURL: URL(fileURLWithPath: "/tmp/README.md"))

        XCTAssertEqual(page.markdown, "# README\n\nHola")
        XCTAssertEqual(library.drawings[page.id], page)
    }

    func testImportingSomethingThatIsNotUTF8TextFails() {
        let reader = FakeFileReader()
        reader.data = Data([0xC3, 0x28, 0xA0, 0xA1])
        let useCase = ImportMarkdownPageUseCase(reader: reader, addPage: AddMarkdownPageUseCase(drawings: library))

        XCTAssertThrowsError(try useCase.execute(notebookID: notebookID, fileURL: URL(fileURLWithPath: "/tmp/x.md"))) {
            XCTAssertEqual($0 as? DrawingError, .importFailed)
        }
        XCTAssertTrue(library.drawings.isEmpty)
    }

    // MARK: - Exportar

    func testExportingWritesAnMdFileWithTheText() throws {
        let page = Drawing.sample(notebookID: notebookID, kind: .markdown, markdown: "# Spec\n\nTexto")
        try library.save(page)
        let store = SpyExportFileStore()

        let url = try ExportMarkdownUseCase(drawings: library, store: store).execute(id: page.id, name: "Física: Hoja 2")

        XCTAssertEqual(url.lastPathComponent, "Física- Hoja 2.md")
        XCTAssertEqual(store.written.first?.data, Data("# Spec\n\nTexto".utf8))
    }

    func testExportingADrawingPageAsMarkdownFails() throws {
        let page = Drawing.sample(notebookID: notebookID)
        try library.save(page)

        XCTAssertThrowsError(try ExportMarkdownUseCase(drawings: library, store: SpyExportFileStore())
            .execute(id: page.id, name: "Hoja")) {
            XCTAssertEqual($0 as? DrawingError, .drawingNotFound)
        }
    }
}
