import XCTest

/// Pruebas de interfaz del iPad: el lienzo: dibujar con el dedo, deshacer,
/// papel, suavizar y zoom.
final class CanvasUITests: DrawPadUITestCase {
    // MARK: - Lienzo

    func testTouchingTheCanvasWithAFingerDoesNotCrash() {
        openNewNotebook()

        tapCanvas()
        dragOnCanvas()

        assertAppIsRunning()
    }

    func testDrawingWithTheFingerEnabledDoesNotCrash() {
        openNewNotebook()
        enableFingerDrawing()

        dragOnCanvas()
        tapCanvas()

        assertAppIsRunning()
    }

    func testUndoRedoAndClearDoNotCrash() {
        openNewNotebook()
        enableFingerDrawing()
        dragOnCanvas()

        app.buttons["Deshacer"].tap()
        app.buttons["Rehacer"].tap()
        chooseMoreAction("Borrar todo")
        app.buttons["Borrar todo"].firstMatch.tap()
        tapCanvas()

        assertAppIsRunning()
    }

    func testChangingTheBackgroundSurvivesReopeningTheDrawing() {
        openNewNotebook()

        chooseBackground("Cuadrícula")
        enableFingerDrawing()
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
        enableFingerDrawing()
        dragOnCanvas()
        goBackToGallery()
        app.buttons["Cuaderno 1"].tap()
        XCTAssertTrue(app.buttons["Fondo"].waitForExistence(timeout: 5))
        chooseBackground("Papel oscuro")

        assertAppIsRunning()
    }

    // MARK: - Suavizar

    func testSmoothingStrokesCanBeRepeatedAndUndone() {
        openNewNotebook()
        enableFingerDrawing()
        dragOnCanvas()
        canvasPoint(0.3, 0.7).press(forDuration: 0.1, thenDragTo: canvasPoint(0.6, 0.3))

        chooseMoreAction("Suavizar trazos")
        chooseMoreAction("Suavizar trazos")
        app.buttons["Deshacer"].tap()
        app.buttons["Rehacer"].tap()
        dragOnCanvas()

        goBackToGallery()
        app.buttons["Cuaderno 1"].tap()
        XCTAssertTrue(app.buttons["Compartir"].waitForExistence(timeout: 5))
        assertAppIsRunning()
    }

    func testSmoothingAnEmptyPageDoesNotCrash() {
        openNewNotebook()

        chooseMoreAction("Suavizar trazos")
        tapCanvas()

        assertAppIsRunning()
    }

    // MARK: - Zoom

    func testZoomingScrollingAndDrawingDoesNotCrash() {
        openNewNotebook()
        let window = app.windows.firstMatch

        window.pinch(withScale: 2.5, velocity: 2)
        dragOnCanvas() // Sin "dibujar con el dedo", un dedo desplaza la hoja.
        chooseBackground("Cuadrícula")
        enableFingerDrawing()
        dragOnCanvas()
        window.pinch(withScale: 0.4, velocity: -2)
        tapCanvas()

        assertAppIsRunning()
    }
}
