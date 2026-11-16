import XCTest

/// Pruebas de interfaz: lanzan la app real en el simulador y la tocan.
///
/// En el simulador todo toque es un "dedo" (no hay Apple Pencil), así que
/// estas pruebas cubren justo lo que las unitarias no pueden: que PencilKit,
/// la navegación entre cuadernos y hojas y la base de datos aguanten toques
/// reales sin cerrarse.
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

    // MARK: - Galería de cuadernos

    func testTheGalleryStartsEmpty() {
        XCTAssertTrue(app.staticTexts["Aún no hay cuadernos"].waitForExistence(timeout: 5))
    }

    func testANewNotebookAppearsInTheGalleryAndCanBeReopened() {
        openNewNotebook()
        app.buttons["Dibujar con el dedo"].tap()
        dragOnCanvas()

        goBackToGallery()
        XCTAssertTrue(app.buttons["Cuaderno 1"].waitForExistence(timeout: 5))

        app.buttons["Cuaderno 1"].tap()
        XCTAssertTrue(app.buttons["Compartir"].waitForExistence(timeout: 5))
        assertPageLabel(contains: "Cuaderno 1 · Hoja 1 de 1")
        assertAppIsRunning()
    }

    func testEachNewNotebookGetsItsOwnCard() {
        openNewNotebook()
        goBackToGallery()
        openNewNotebook()
        goBackToGallery()

        XCTAssertTrue(app.buttons["Cuaderno 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Cuaderno 2"].exists)
    }

    // MARK: - Hojas

    func testAddingPagesMovingBetweenThemAndDeletingOne() {
        openNewNotebook()
        assertPageLabel(contains: "Hoja 1 de 1")
        XCTAssertFalse(app.buttons["Hoja anterior"].isEnabled)
        XCTAssertFalse(app.buttons["Hoja siguiente"].isEnabled)

        choosePageAction("Nueva hoja")
        assertPageLabel(contains: "Hoja 2 de 2")
        app.buttons["Dibujar con el dedo"].tap()
        dragOnCanvas()

        app.buttons["Hoja anterior"].tap()
        assertPageLabel(contains: "Hoja 1 de 2")
        dragOnCanvas() // "Dibujar con el dedo" sigue activo al cambiar de hoja.
        app.buttons["Hoja siguiente"].tap()
        assertPageLabel(contains: "Hoja 2 de 2")

        choosePageAction("Eliminar esta hoja")
        app.buttons["Eliminar hoja"].firstMatch.tap()
        assertPageLabel(contains: "Hoja 1 de 1")

        tapCanvas()
        goBackToGallery()
        XCTAssertTrue(app.buttons["Cuaderno 1"].waitForExistence(timeout: 5))
        assertAppIsRunning()
    }

    func testANewPageKeepsThePaperOfThePreviousOne() {
        openNewNotebook()
        chooseBackground("Cuadrícula")

        choosePageAction("Nueva hoja")
        assertPageLabel(contains: "Hoja 2 de 2")

        app.buttons["Fondo"].tap()
        let grid = app.buttons["Cuadrícula"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        XCTAssertTrue(grid.isSelected)
        grid.tap()
        assertAppIsRunning()
    }

    // MARK: - Lienzo

    func testTouchingTheCanvasWithAFingerDoesNotCrash() {
        openNewNotebook()

        tapCanvas()
        dragOnCanvas()

        assertAppIsRunning()
    }

    func testDrawingWithTheFingerEnabledDoesNotCrash() {
        openNewNotebook()
        app.buttons["Dibujar con el dedo"].tap()

        dragOnCanvas()
        tapCanvas()

        assertAppIsRunning()
    }

    func testUndoRedoAndClearDoNotCrash() {
        openNewNotebook()
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
        openNewNotebook()

        chooseBackground("Cuadrícula")
        app.buttons["Dibujar con el dedo"].tap()
        dragOnCanvas()
        goBackToGallery()
        app.buttons["Cuaderno 1"].tap()
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
        openNewNotebook()

        for title in ["Cuadrícula", "Líneas", "Puntos", "Blanco"] {
            chooseBackground(title)
        }
        tapCanvas()
        assertAppIsRunning()
    }

    func testDrawingOnDarkPaperDoesNotCrash() {
        openNewNotebook()

        chooseBackground("Papel oscuro")
        chooseBackground("Puntos")
        app.buttons["Dibujar con el dedo"].tap()
        dragOnCanvas()
        goBackToGallery()
        app.buttons["Cuaderno 1"].tap()
        XCTAssertTrue(app.buttons["Fondo"].waitForExistence(timeout: 5))
        chooseBackground("Papel oscuro")

        assertAppIsRunning()
    }

    // MARK: - Zoom

    func testZoomingScrollingAndDrawingDoesNotCrash() {
        openNewNotebook()
        let window = app.windows.firstMatch

        window.pinch(withScale: 2.5, velocity: 2)
        dragOnCanvas() // Sin "dibujar con el dedo", un dedo desplaza la hoja.
        chooseBackground("Cuadrícula")
        app.buttons["Dibujar con el dedo"].tap()
        dragOnCanvas()
        window.pinch(withScale: 0.4, velocity: -2)
        tapCanvas()

        assertAppIsRunning()
    }

    // MARK: - Compartir

    func testSharingAnEmptyCanvasShowsAnAlert() {
        openNewNotebook()

        app.buttons["Compartir"].tap()
        app.buttons["Compartir como PDF"].tap()

        XCTAssertTrue(app.alerts["Algo salió mal"].waitForExistence(timeout: 5))
        app.alerts.buttons["Aceptar"].tap()
        assertAppIsRunning()
    }

    func testSharingADrawingAsImageDoesNotCrash() {
        shareDrawing(option: "Compartir como imagen")
    }

    func testSharingADrawingAsPDFDoesNotCrash() {
        shareDrawing(option: "Compartir como PDF")
    }

    // MARK: - Utilidades

    /// Dibuja algo y abre la hoja de compartir. La hoja es del sistema: basta
    /// con comprobar que la app sigue viva y no mostró un error.
    private func shareDrawing(option: String) {
        openNewNotebook()
        app.buttons["Dibujar con el dedo"].tap()
        dragOnCanvas()

        app.buttons["Compartir"].tap()
        app.buttons[option].tap()

        XCTAssertFalse(app.alerts["Algo salió mal"].waitForExistence(timeout: 3))
        assertAppIsRunning()
    }

    private func chooseBackground(_ title: String) {
        app.buttons["Fondo"].tap()
        // Según la versión de iOS, un interruptor dentro de un menú puede ser
        // un botón o un switch: se busca por nombre, sea del tipo que sea.
        let option = app.descendants(matching: .any).matching(identifier: title).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
    }

    private func openNewNotebook() {
        let newNotebook = app.buttons["Nuevo cuaderno"]
        XCTAssertTrue(newNotebook.waitForExistence(timeout: 5))
        newNotebook.tap()
        XCTAssertTrue(app.buttons["Compartir"].waitForExistence(timeout: 5))
    }

    private func goBackToGallery() {
        app.navigationBars.buttons["Cuadernos"].tap()
        XCTAssertTrue(app.buttons["Nuevo cuaderno"].waitForExistence(timeout: 5))
    }

    /// Abre el menú de hojas (el título de la barra) y elige una acción.
    private func choosePageAction(_ title: String) {
        app.buttons["Hojas"].tap()
        let action = app.buttons[title]
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        action.tap()
    }

    /// Espera a que el título de la barra diga, por ejemplo, "Hoja 2 de 3".
    private func assertPageLabel(contains text: String, file: StaticString = #filePath, line: UInt = #line) {
        let label = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: label, object: app.buttons["Hojas"])
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "El título no muestra \"\(text)\"", file: file, line: line)
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
