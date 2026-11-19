import XCTest
@testable import DrawPad

final class JSONNotebookArchiveCoderTests: XCTestCase {
    private let coder = JSONNotebookArchiveCoder()

    /// Un cuaderno con todo lo que puede tener: tapa dibujada, hojas con papel
    /// distinto y todos los tipos de elemento.
    private func fullBundle() -> NotebookBundle {
        let notebook = Notebook.sample(
            title: "Arquitectura",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000.25),
            cover: NotebookCover(
                color: .purple, style: .drawn,
                drawing: CoverDrawing(strokesData: Data("tapa".utf8), imageData: Data("png".utf8))
            )
        )
        let first = Drawing.sample(
            notebookID: notebook.id, strokes: "trazos", thumbnail: "mini",
            createdAt: Date(timeIntervalSince1970: 1), updatedAt: Date(timeIntervalSince1970: 5),
            background: .dots, theme: .dark
        )
        let second = Drawing.sample(notebookID: notebook.id, createdAt: Date(timeIntervalSince1970: 2))
        let api = PageElement.sampleShape(pageID: second.id, .rectangle, label: "API")
        let queue = PageElement.sampleShape(pageID: second.id, .cylinder, label: "Kafka", quarterTurns: 1)
        return NotebookBundle(
            notebook: notebook,
            pages: [first, second],
            elements: [
                .sampleText(pageID: first.id, "Hola\nmundo"),
                .sampleImage(pageID: first.id, data: "imagen"),
                api,
                queue,
                .sampleConnector(pageID: second.id, from: api.id, to: queue.id, style: .line),
                .sampleMermaid(pageID: second.id, source: "graph TD\n A-->B", image: "diagrama"),
            ]
        )
    }

    func testAWrittenNotebookReadsBackExactlyTheSame() throws {
        let bundle = fullBundle()

        let decoded = try coder.decode(try coder.encode(bundle))

        XCTAssertEqual(decoded, bundle)
        XCTAssertEqual(coder.fileExtension, "drawpad")
    }

    func testTheFileSaysWhatItIsAndWhichVersion() throws {
        let json = try JSONSerialization.jsonObject(with: try coder.encode(fullBundle())) as? [String: Any]

        XCTAssertEqual(json?["format"] as? String, "drawpad-notebook")
        XCTAssertEqual(json?["version"] as? Int, JSONNotebookArchiveCoder.currentVersion)
    }

    func testSomethingThatIsNotANotebookIsRejected() {
        let notNotebooks = [
            Data("no soy json".utf8),
            Data("{}".utf8),
            Data(#"{"format": "otra-app", "version": 1}"#.utf8),
            // Cabecera correcta pero sin contenido.
            Data(#"{"format": "drawpad-notebook", "version": 1}"#.utf8),
        ]
        for data in notNotebooks {
            XCTAssertThrowsError(try coder.decode(data)) { error in
                XCTAssertEqual(error as? DrawingError, .importFailed)
            }
        }
    }

    func testAFileFromANewerVersionGivesItsOwnError() {
        let future = Data(#"{"format": "drawpad-notebook", "version": 99, "algoNuevo": true}"#.utf8)

        XCTAssertThrowsError(try coder.decode(future)) { error in
            XCTAssertEqual(error as? DrawingError, .unsupportedArchiveVersion)
        }
    }

    func testUnknownValuesFallBackAndUnknownElementsAreSkipped() throws {
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try coder.encode(fullBundle())) as? [String: Any]
        )
        var notebook = try XCTUnwrap(json["notebook"] as? [String: Any])
        notebook["coverColor"] = "fucsia"
        json["notebook"] = notebook
        var pages = try XCTUnwrap(json["pages"] as? [[String: Any]])
        pages[0]["background"] = "hexagonos"
        json["pages"] = pages
        var elements = try XCTUnwrap(json["elements"] as? [[String: Any]])
        elements[0]["kind"] = "holograma"
        json["elements"] = elements

        let decoded = try coder.decode(try JSONSerialization.data(withJSONObject: json))

        XCTAssertEqual(decoded.notebook.cover.color, NotebookCover.standard.color)
        XCTAssertEqual(decoded.notebook.cover.style, .drawn)
        XCTAssertEqual(decoded.pages[0].background, .blank)
        XCTAssertEqual(decoded.elements.count, fullBundle().elements.count - 1)
    }
}
