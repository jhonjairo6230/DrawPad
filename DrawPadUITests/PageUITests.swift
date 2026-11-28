import XCTest

/// Pruebas de interfaz del iPad: hojas de un cuaderno (de dibujo y Markdown) y
/// compartir una hoja.
final class PageUITests: DrawPadUITestCase {
    // MARK: - Hojas

    func testAddingPagesMovingBetweenThemAndDeletingOne() {
        openNewNotebook()
        assertPageLabel(contains: "Hoja 1 de 1")
        XCTAssertFalse(app.buttons["Hoja anterior"].isEnabled)
        XCTAssertFalse(app.buttons["Hoja siguiente"].isEnabled)

        chooseMenuAction("Hoja de dibujo", inMenu: "Nueva hoja")
        assertPageLabel(contains: "Hoja 2 de 2")
        enableFingerDrawing()
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

        chooseMenuAction("Hoja de dibujo", inMenu: "Nueva hoja")
        assertPageLabel(contains: "Hoja 2 de 2")

        app.buttons["Fondo"].tap()
        let grid = app.buttons["Cuadrícula"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        XCTAssertTrue(grid.isSelected)
        grid.tap()
        assertAppIsRunning()
    }

    func testAMarkdownPageCanBeWrittenAndRead() {
        openNewNotebook()
        chooseMenuAction("Hoja Markdown", inMenu: "Nueva hoja")
        assertPageLabel(contains: "Hoja 2 de 2")
        // La plantilla ya trae un spec de ejemplo, formateado.
        XCTAssertTrue(app.buttons["Editar"].waitForExistence(timeout: 5))

        app.buttons["Editar"].tap()
        let editor = app.textViews["Texto Markdown"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        // Al final del texto, para no escribir dentro del bloque mermaid.
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)).tap()
        editor.typeText("\n\n# Notas de prueba\n")

        app.buttons["Ver"].tap()
        XCTAssertTrue(app.staticTexts["Notas de prueba"].waitForExistence(timeout: 10))

        // Lo escrito sigue ahí al volver a la hoja.
        app.buttons["Hoja anterior"].tap()
        assertPageLabel(contains: "Hoja 1 de 2")
        app.buttons["Hoja siguiente"].tap()
        XCTAssertTrue(app.staticTexts["Notas de prueba"].waitForExistence(timeout: 10))
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
}
