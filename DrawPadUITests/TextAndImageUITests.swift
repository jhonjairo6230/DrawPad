import XCTest

/// Pruebas de interfaz del iPad: cuadros de texto e imágenes pegadas en la
/// hoja.
final class TextAndImageUITests: DrawPadUITestCase {
    // MARK: - Texto e imágenes

    func testATextBoxCanBeTypedMovedEditedAndDeleted() {
        openNewNotebook()

        insertTextBox("Hola")
        // Recién insertado queda seleccionado, en el modo de mover.
        XCTAssertTrue(app.buttons["Listo"].waitForExistence(timeout: 5))
        let box = app.staticTexts["Hola"]
        // `XCUIElement` solo arrastra hasta otro elemento; hasta un punto de la
        // pantalla hay que arrastrar desde una coordenada.
        box.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.2, thenDragTo: canvasPoint(0.3, 0.7))

        app.buttons["Editar texto"].tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(" mundo")
        app.buttons["Guardar"].tap()
        XCTAssertTrue(app.staticTexts["Hola mundo"].waitForExistence(timeout: 5))

        app.buttons["Eliminar"].tap()
        XCTAssertFalse(app.staticTexts["Hola mundo"].waitForExistence(timeout: 2))
        app.buttons["Listo"].tap()
        tapCanvas()
        assertAppIsRunning()
    }

    func testTextStaysOnThePageAndCanBeDrawnOver() {
        openNewNotebook()

        insertTextBox("Apunte")
        app.buttons["Listo"].tap()
        enableFingerDrawing()
        dragOnCanvas() // Fuera del modo de mover, el dedo dibuja por encima.
        XCTAssertTrue(app.staticTexts["Apunte"].exists)

        goBackToGallery()
        app.buttons["Cuaderno 1"].tap()
        XCTAssertTrue(app.staticTexts["Apunte"].waitForExistence(timeout: 5))
        assertAppIsRunning()
    }

    func testPastingPutsTheClipboardTextOnThePage() {
        openNewNotebook()

        // En las pruebas el portapapeles es fijo (ver AppContainer).
        chooseInsertAction("Pegar")

        XCTAssertTrue(app.staticTexts["Texto pegado"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Listo"].exists)
        assertAppIsRunning()
    }

    func testAPageWithOnlyTextCanBeSharedAsPDF() {
        openNewNotebook()
        insertTextBox("Solo texto")
        app.buttons["Listo"].tap()

        app.buttons["Compartir"].tap()
        app.buttons["Compartir como PDF"].tap()

        XCTAssertFalse(app.alerts["Algo salió mal"].waitForExistence(timeout: 3))
        assertAppIsRunning()
    }
}
