import UIKit
import XCTest
@testable import DrawPad

/// Prueba de integración: marked y Mermaid de verdad, dentro de WebKit.
@MainActor
final class WebKitMarkdownRendererTests: XCTestCase {
    private var window: UIWindow?

    private func makeRenderer() -> WebKitMarkdownRenderer {
        let renderer = WebKitMarkdownRenderer()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 1000))
        renderer.webView.frame = window.bounds
        window.addSubview(renderer.webView)
        window.isHidden = false
        self.window = window
        return renderer
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
    }

    func testMarkedIsBundledWithTheApp() {
        XCTAssertNotNil(WebKitMarkdownRenderer.markedScript)
    }

    func testAGitHubStyleDocumentIsFormattedWithItsDiagram() async throws {
        let renderer = makeRenderer()
        let markdown = """
        # Spec

        ## Tabla

        | Servicio | Puerto |
        |----------|--------|
        | API      | 8080   |

        - [x] Hecho
        - [ ] Pendiente

        ```mermaid
        flowchart LR
            A --> B
        ```
        """

        let rendered = await renderer.render(markdown)
        let summary = try XCTUnwrap(rendered)

        XCTAssertEqual(summary.headings, 2)
        XCTAssertEqual(summary.tables, 1)
        XCTAssertEqual(summary.taskItems, 2)
        XCTAssertEqual(summary.diagrams, 1)
        XCTAssertEqual(summary.diagramErrors, 0)
    }

    func testHTMLInsideTheDocumentIsShownAsTextNotRun() async throws {
        let renderer = makeRenderer()

        let rendered = await renderer.render("Hola\n\n<script>alert('x')</script>\n")
        let summary = try XCTUnwrap(rendered)

        XCTAssertEqual(summary.scripts, 0)
    }

    func testABrokenDiagramIsReportedAndTheRestStillShows() async throws {
        let renderer = makeRenderer()

        let rendered = await renderer.render("# Título\n\n```mermaid\nflowchart LR\n  A -->\n```\n")
        let summary = try XCTUnwrap(rendered)

        XCTAssertEqual(summary.headings, 1)
        XCTAssertEqual(summary.diagrams, 0)
        XCTAssertEqual(summary.diagramErrors, 1)
    }
}
