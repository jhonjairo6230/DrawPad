import XCTest

/// Pruebas de interfaz: lanzan la app real en el simulador y la tocan.
///
/// En el simulador todo toque es un "dedo" (no hay Apple Pencil), así que
/// estas pruebas cubren justo lo que las unitarias no pueden: que PencilKit,
/// la navegación y la base de datos aguanten toques reales sin cerrarse.
///
/// Cada prueba arranca con `-uiTesting`: una base de datos vacía en memoria.
final class CanvasUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    // MARK: - Galería

    func testTheGalleryStartsEmpty() {
        XCTAssertTrue(app.staticTexts["Aún no hay dibujos"].waitForExistence(timeout: 5))
    }

    func testANewDrawingAppearsInTheGalleryAndCanBeReopened() {
        openNewDrawing()
        app.buttons["Dibujar con el dedo"].tap()
        dragOnCanvas()

        goBackToGallery()
        XCTAssertTrue(app.buttons["Dibujo 1"].waitForExistence(timeout: 5))

        app.buttons["Dibujo 1"].tap()
        XCTAssertTrue(app.buttons["Guardar en Fotos"].waitForExistence(timeout: 5))
        assertAppIsRunning()
    }

    func testEachNewDrawingGetsItsOwnCard() {
        openNewDrawing()
        goBackToGallery()
        openNewDrawing()
        goBackToGallery()

        XCTAssertTrue(app.buttons["Dibujo 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Dibujo 2"].exists)
    }

    // MARK: - Lienzo

    func testTouchingTheCanvasWithAFingerDoesNotCrash() {
        openNewDrawing()

        tapCanvas()
        dragOnCanvas()

        assertAppIsRunning()
    }

    func testDrawingWithTheFingerEnabledDoesNotCrash() {
        openNewDrawing()
        app.buttons["Dibujar con el dedo"].tap()

        dragOnCanvas()
        tapCanvas()

        assertAppIsRunning()
    }

    func testUndoRedoAndClearDoNotCrash() {
        openNewDrawing()
        app.buttons["Dibujar con el dedo"].tap()
        dragOnCanvas()

        app.buttons["Deshacer"].tap()
        app.buttons["Rehacer"].tap()
        app.buttons["Borrar todo"].tap()
        app.buttons["Borrar todo"].firstMatch.tap()
        tapCanvas()

        assertAppIsRunning()
    }

    func testChangingTheBackgroundSurvivesReopeningTheDrawing() {
        openNewDrawing()

        chooseBackground("Cuadrícula")
        app.buttons["Dibujar con el dedo"].tap()
        dragOnCanvas()
        goBackToGallery()
        app.buttons["Dibujo 1"].tap()
        XCTAssertTrue(app.buttons["Fondo"].waitForExistence(timeout: 5))

        // El menú marca como seleccionado el fondo guardado.
        app.buttons["Fondo"].tap()
        let grid = app.buttons["Cuadrícula"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        XCTAssertTrue(grid.isSelected)
        grid.tap()
        assertAppIsRunning()
    }

    func testEveryBackgroundCanBeChosenWithoutCrashing() {
        openNewDrawing()

        for title in ["Cuadrícula", "Líneas", "Puntos", "Blanco"] {
            chooseBackground(title)
        }
        tapCanvas()

        assertAppIsRunning()
    }

    // MARK: - Utilidades

    private func chooseBackground(_ title: String) {
        app.buttons["Fondo"].tap()
        let option = app.buttons[title]
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
    }

    private func openNewDrawing() {
        let newDrawing = app.buttons["Nuevo dibujo"]
        XCTAssertTrue(newDrawing.waitForExistence(timeout: 5))
        newDrawing.tap()
        XCTAssertTrue(app.buttons["Guardar en Fotos"].waitForExistence(timeout: 5))
    }

    private func goBackToGallery() {
        app.navigationBars.buttons["Dibujos"].tap()
        XCTAssertTrue(app.buttons["Nuevo dibujo"].waitForExistence(timeout: 5))
    }

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
