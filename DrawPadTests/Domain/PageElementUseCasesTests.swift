import XCTest
@testable import DrawPad

final class PageElementUseCasesTests: XCTestCase {
    private let pageID = UUID()
    private let center = CGPoint(x: 400, y: 300)
    private let maxImageSize = CGSize(width: 480, height: 360)

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    // MARK: - Listar

    func testListReturnsOnlyThatPageOldestFirst() throws {
        let first = PageElement.sampleText(pageID: pageID, "uno", createdAt: date(1))
        let second = PageElement.sampleImage(pageID: pageID, createdAt: date(2))
        let library = InMemoryLibrary(elements: [second, first, .sampleText()])

        let listed = try ListPageElementsUseCase(elements: library).execute(pageID: pageID)

        XCTAssertEqual(listed, [first, second])
    }

    // MARK: - Añadir texto

    func testAddTextSavesATrimmedTextBoxCenteredOnThePoint() throws {
        let library = InMemoryLibrary()
        let now = date(10)
        let useCase = AddTextElementUseCase(elements: library, now: { now })

        let element = try useCase.execute(pageID: pageID, text: "  Hola\n", centeredAt: center)

        XCTAssertEqual(element.content, .text("Hola"))
        XCTAssertEqual(element.pageID, pageID)
        XCTAssertEqual(element.createdAt, now)
        XCTAssertEqual(element.frame.width, PageElementLayout.textWidth)
        XCTAssertEqual(element.frame.midX, center.x, accuracy: 0.001)
        XCTAssertEqual(element.frame.midY, center.y, accuracy: 0.001)
        XCTAssertEqual(library.elements[element.id], element)
    }

    func testAddTextRejectsBlankText() {
        let library = InMemoryLibrary()
        let useCase = AddTextElementUseCase(elements: library)

        XCTAssertThrowsError(try useCase.execute(pageID: pageID, text: " \n ", centeredAt: center)) { error in
            XCTAssertEqual(error as? DrawingError, .emptyText)
        }
        XCTAssertTrue(library.elements.isEmpty)
    }

    func testAnElementNearTheCornerStaysInsideThePage() throws {
        let useCase = AddTextElementUseCase(elements: InMemoryLibrary())

        let element = try useCase.execute(pageID: pageID, text: "Hola", centeredAt: CGPoint(x: 5, y: 5))

        XCTAssertEqual(element.frame.origin, .zero)
    }

    // MARK: - Añadir imagen

    func testAddImageKeepsASmallImageAtItsSize() throws {
        let library = InMemoryLibrary()
        let useCase = AddImageElementUseCase(elements: library)

        let element = try useCase.execute(
            pageID: pageID, imageData: Data("img".utf8), imageSize: CGSize(width: 200, height: 100),
            centeredAt: center, maxSize: maxImageSize
        )

        XCTAssertEqual(element.content, .image(Data("img".utf8)))
        XCTAssertEqual(element.frame, CGRect(x: 300, y: 250, width: 200, height: 100))
        XCTAssertEqual(library.elements[element.id], element)
    }

    func testAddImageShrinksALargeImageKeepingItsProportion() throws {
        let useCase = AddImageElementUseCase(elements: InMemoryLibrary())

        let element = try useCase.execute(
            pageID: pageID, imageData: Data("img".utf8), imageSize: CGSize(width: 2000, height: 1000),
            centeredAt: center, maxSize: maxImageSize
        )

        // Limita el ancho: 2000 → 480, y el alto baja en la misma proporción.
        XCTAssertEqual(element.frame.size.width, 480, accuracy: 0.001)
        XCTAssertEqual(element.frame.size.height, 240, accuracy: 0.001)
    }

    func testFitNeverEnlarges() {
        let small = CGSize(width: 10, height: 20)

        XCTAssertEqual(AddImageElementUseCase.fit(small, within: maxImageSize), small)
    }

    func testFitIsLimitedByTheTighterSide() {
        let tall = CGSize(width: 500, height: 1440)

        let fitted = AddImageElementUseCase.fit(tall, within: maxImageSize)

        XCTAssertEqual(fitted.height, 360, accuracy: 0.001)
        XCTAssertEqual(fitted.width, 125, accuracy: 0.001)
    }

    func testAddImageRejectsAnImageWithoutDataOrSize() {
        let library = InMemoryLibrary()
        let useCase = AddImageElementUseCase(elements: library)

        XCTAssertThrowsError(try useCase.execute(
            pageID: pageID, imageData: Data(), imageSize: CGSize(width: 10, height: 10),
            centeredAt: center, maxSize: maxImageSize
        ))
        XCTAssertThrowsError(try useCase.execute(
            pageID: pageID, imageData: Data("img".utf8), imageSize: .zero,
            centeredAt: center, maxSize: maxImageSize
        ))
        XCTAssertTrue(library.elements.isEmpty)
    }

    // MARK: - Pegar

    private func makePaste(_ clipboard: FakeClipboard, _ library: InMemoryLibrary) -> PasteElementUseCase {
        PasteElementUseCase(
            clipboard: clipboard,
            addText: AddTextElementUseCase(elements: library),
            addImage: AddImageElementUseCase(elements: library)
        )
    }

    func testPasteAddsTheCopiedText() throws {
        let library = InMemoryLibrary()
        let useCase = makePaste(FakeClipboard(.text("Copiado")), library)

        let element = try useCase.execute(pageID: pageID, centeredAt: center, maxImageSize: maxImageSize)

        XCTAssertEqual(element.content, .text("Copiado"))
        XCTAssertEqual(library.elements.count, 1)
    }

    func testPasteAddsTheCopiedImageFittedToTheLimit() throws {
        let library = InMemoryLibrary()
        let clipboard = FakeClipboard(.image(data: Data("img".utf8), size: CGSize(width: 960, height: 720)))

        let element = try makePaste(clipboard, library)
            .execute(pageID: pageID, centeredAt: center, maxImageSize: maxImageSize)

        XCTAssertEqual(element.content, .image(Data("img".utf8)))
        XCTAssertEqual(element.frame.size.width, 480, accuracy: 0.001)
        XCTAssertEqual(element.frame.size.height, 360, accuracy: 0.001)
    }

    func testPasteWithAnEmptyClipboardFails() {
        let library = InMemoryLibrary()
        let useCase = makePaste(FakeClipboard(nil), library)

        XCTAssertThrowsError(
            try useCase.execute(pageID: pageID, centeredAt: center, maxImageSize: maxImageSize)
        ) { error in
            XCTAssertEqual(error as? DrawingError, .clipboardEmpty)
        }
        XCTAssertTrue(library.elements.isEmpty)
    }

    func testPastingOnlySpacesCountsAsAnEmptyClipboard() {
        let useCase = makePaste(FakeClipboard(.text("   ")), InMemoryLibrary())

        XCTAssertThrowsError(
            try useCase.execute(pageID: pageID, centeredAt: center, maxImageSize: maxImageSize)
        ) { error in
            XCTAssertEqual(error as? DrawingError, .clipboardEmpty)
        }
    }

    // MARK: - Editar texto

    func testUpdateTextChangesOnlyTheText() throws {
        let element = PageElement.sampleText(pageID: pageID, "Viejo")
        let library = InMemoryLibrary(elements: [element])

        let updated = try UpdateElementTextUseCase(elements: library).execute(id: element.id, text: " Nuevo ")

        var expected = element
        expected.content = .text("Nuevo")
        XCTAssertEqual(updated, expected)
        XCTAssertEqual(library.elements[element.id], expected)
    }

    func testUpdateTextRejectsBlankText() {
        let element = PageElement.sampleText("Viejo")
        let library = InMemoryLibrary(elements: [element])
        let useCase = UpdateElementTextUseCase(elements: library)

        XCTAssertThrowsError(try useCase.execute(id: element.id, text: "  ")) { error in
            XCTAssertEqual(error as? DrawingError, .emptyText)
        }
        XCTAssertEqual(library.elements[element.id], element)
    }

    func testUpdateTextFailsOnAnImageOrAMissingElement() {
        let image = PageElement.sampleImage()
        let useCase = UpdateElementTextUseCase(elements: InMemoryLibrary(elements: [image]))

        for id in [image.id, UUID()] {
            XCTAssertThrowsError(try useCase.execute(id: id, text: "Algo")) { error in
                XCTAssertEqual(error as? DrawingError, .elementNotFound)
            }
        }
    }

    // MARK: - Mover

    func testMoveSavesTheNewFrame() throws {
        let element = PageElement.sampleImage(pageID: pageID)
        let library = InMemoryLibrary(elements: [element])
        let frame = CGRect(x: 120, y: 80, width: 300, height: 150)

        let moved = try MoveElementUseCase(elements: library).execute(id: element.id, frame: frame)

        XCTAssertEqual(moved.frame, frame)
        XCTAssertEqual(library.elements[element.id]?.frame, frame)
        XCTAssertEqual(moved.content, element.content)
    }

    func testMoveKeepsTheElementInsideThePageAndBigEnoughToTouch() {
        let dragged = CGRect(x: -30, y: -5, width: 10, height: 0)

        XCTAssertEqual(
            MoveElementUseCase.corrected(dragged),
            CGRect(x: 0, y: 0, width: PageElementLayout.minimumSide, height: 1)
        )
    }

    func testMoveFailsWhenTheElementDoesNotExist() {
        let useCase = MoveElementUseCase(elements: InMemoryLibrary())

        XCTAssertThrowsError(try useCase.execute(id: UUID(), frame: .zero)) { error in
            XCTAssertEqual(error as? DrawingError, .elementNotFound)
        }
    }

    // MARK: - Eliminar

    func testDeleteRemovesOnlyThatElement() throws {
        let kept = PageElement.sampleText(pageID: pageID, "se queda")
        let removed = PageElement.sampleImage(pageID: pageID)
        let library = InMemoryLibrary(elements: [kept, removed])

        try DeleteElementUseCase(elements: library).execute(id: removed.id)

        XCTAssertEqual(Array(library.elements.keys), [kept.id])
    }

    // MARK: - Borrado en cascada (regla de los repositorios)

    func testDeletingAPageOrANotebookDeletesTheirElements() throws {
        let notebook = Notebook.sample()
        let page = Drawing.sample(notebookID: notebook.id, createdAt: date(1))
        let otherPage = Drawing.sample(notebookID: notebook.id, createdAt: date(2))
        let outsider = PageElement.sampleText("otro cuaderno")
        let library = InMemoryLibrary(
            notebooks: [notebook],
            drawings: [page, otherPage],
            elements: [.sampleText(pageID: page.id), .sampleImage(pageID: otherPage.id), outsider]
        )

        try DeletePageUseCase(drawings: library).execute(id: page.id)
        XCTAssertEqual(try library.listElements(pageID: page.id), [])
        XCTAssertEqual(try library.listElements(pageID: otherPage.id).count, 1)

        try DeleteNotebookUseCase(notebooks: library).execute(id: notebook.id)
        XCTAssertEqual(Array(library.elements.keys), [outsider.id])
    }
}
