import UIKit
import XCTest
@testable import DrawPad

/// Prueba de integración: Mermaid de verdad, dentro de WebKit, sin red.
///
/// Comprueba que el JavaScript va dentro de la app y que un diagrama se dibuja
/// y se convierte en imagen. El aspecto final solo se puede juzgar en el iPad.
@MainActor
final class WebKitMermaidPreviewTests: XCTestCase {
    private var window: UIWindow?

    /// La vista web, en una ventana: WebKit dibuja mejor lo que está en pantalla.
    private func makePreview() -> WebKitMermaidPreview {
        let preview = WebKitMermaidPreview()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 800))
        preview.webView.frame = window.bounds
        window.addSubview(preview.webView)
        window.isHidden = false
        self.window = window
        return preview
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
    }

    func testMermaidIsBundledWithTheApp() {
        XCTAssertNotNil(WebKitMermaidPreview.mermaidScript)
        XCTAssertGreaterThan(WebKitMermaidPreview.mermaidScript?.count ?? 0, 1_000_000)
    }

    func testAValidDiagramIsDrawnAndBecomesAnImage() async throws {
        let preview = makePreview()

        let outcome = await preview.render(source: "flowchart LR\n  A[App] --> B[(DB)]", theme: .light)

        guard case .rendered(let size) = outcome else {
            return XCTFail("No se dibujó: \(outcome)")
        }
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)

        let snapshot = try await preview.snapshot()
        XCTAssertNotNil(UIImage(data: snapshot.image))
        XCTAssertGreaterThan(snapshot.size.width, 0)
    }

    func testAnInvalidDiagramReportsMermaidsError() async throws {
        let preview = makePreview()

        let outcome = await preview.render(source: "flowchart LR\n  A -->", theme: .dark)

        guard case .failed(let message) = outcome else {
            return XCTFail("Debía fallar: \(outcome)")
        }
        XCTAssertFalse(message.isEmpty)
        do {
            _ = try await preview.snapshot()
            XCTFail("Sin diagrama no debería haber imagen")
        } catch {
            XCTAssertEqual(error as? DrawingError, .invalidDiagram("no hay ningún diagrama dibujado"))
        }
    }
}
