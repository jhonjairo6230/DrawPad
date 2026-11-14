import XCTest

/// Pruebas de interfaz: lanzan la app real en el simulador y la tocan.
///
/// En el simulador todo toque es un "dedo" (no hay Apple Pencil), así que
/// estas pruebas cubren justo lo que las unitarias no pueden: que PencilKit y
/// la pantalla aguanten toques reales sin cerrarse.
final class CanvasUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testTouchingTheCanvasWithAFingerDoesNotCrash() {
        tapCanvas()
        dragOnCanvas()

        assertAppIsRunning()
    }

    func testDrawingWithTheFingerEnabledDoesNotCrash() {
        app.buttons["Dibujar con el dedo"].tap()

        dragOnCanvas()
        tapCanvas()

        assertAppIsRunning()
    }

    func testUndoRedoAndClearDoNotCrash() {
        app.buttons["Dibujar con el dedo"].tap()
        dragOnCanvas()

        app.buttons["Deshacer"].tap()
        app.buttons["Rehacer"].tap()
        app.buttons["Borrar todo"].tap()
        app.buttons["Borrar todo"].firstMatch.tap()
        tapCanvas()

        assertAppIsRunning()
    }

    // MARK: - Utilidades

    private func canvasPoint(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
    }

    private func tapCanvas() {
        canvasPoint(0.5, 0.5).tap()
    }

    private func dragOnCanvas() {
        canvasPoint(0.3, 0.4).press(forDuration: 0.1, thenDragTo: canvasPoint(0.7, 0.6))
    }

    private func assertAppIsRunning(file: StaticString = #filePath, line: UInt = #line) {
        // Deja tiempo a que un cierre diferido llegue a ocurrir.
        _ = app.wait(for: .notRunning, timeout: 2)
        XCTAssertEqual(app.state, .runningForeground, "La app se cerró", file: file, line: line)
    }
}
