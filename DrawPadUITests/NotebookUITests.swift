import XCTest

/// Pruebas de interfaz del iPad de los cuadernos: crearlos, abrirlos, su
/// portada y exportarlos.
final class NotebookUITests: DrawPadUITestCase {
    // MARK: - Galería de cuadernos

    func testTheGalleryStartsEmpty() {
        XCTAssertTrue(app.staticTexts["Aún no hay cuadernos"].waitForExistence(timeout: 5))
    }

    func testANewNotebookAppearsInTheGalleryAndCanBeReopened() {
        openNewNotebook()
        enableFingerDrawing()
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

    // MARK: - Portada

    func testChangingTheCoverIsRememberedByTheEditor() {
        openNewNotebook()
        goBackToGallery()

        openCoverEditor(of: "Cuaderno 1")
        app.buttons["Rojo"].tap()
        app.buttons["Lomo"].tap()
        app.buttons["Guardar"].tap()
        XCTAssertTrue(app.buttons["Cuaderno 1"].waitForExistence(timeout: 5))

        openCoverEditor(of: "Cuaderno 1")
        XCTAssertTrue(app.buttons["Rojo"].isSelected)
        XCTAssertFalse(app.buttons["Azul"].isSelected)
        app.buttons["Cancelar"].tap()
        assertAppIsRunning()
    }

    func testCancellingTheCoverEditorKeepsTheOldCover() {
        openNewNotebook()
        goBackToGallery()

        openCoverEditor(of: "Cuaderno 1")
        app.buttons["Verde"].tap()
        app.buttons["Cancelar"].tap()

        openCoverEditor(of: "Cuaderno 1")
        // El primer cuaderno nace con la primera tapa de la lista: azul.
        XCTAssertTrue(app.buttons["Azul"].isSelected)
        XCTAssertFalse(app.buttons["Verde"].isSelected)
    }

    func testDrawingTheCoverAndKeepingItAfterReopeningTheEditor() {
        openNewNotebook()
        goBackToGallery()

        openCoverEditor(of: "Cuaderno 1")
        app.buttons["Dibujo"].tap()
        drawCover()

        // De vuelta en el editor, ya hay dibujo.
        XCTAssertTrue(app.buttons["Editar dibujo"].waitForExistence(timeout: 5))
        app.buttons["Guardar"].tap()
        XCTAssertTrue(app.buttons["Cuaderno 1"].waitForExistence(timeout: 5))

        openCoverEditor(of: "Cuaderno 1")
        XCTAssertTrue(app.buttons["Editar dibujo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Quitar dibujo"].exists)
        app.buttons["Cancelar"].tap()
        assertAppIsRunning()
    }

    func testCancellingTheCoverDrawingDoesNotAddADrawing() {
        openNewNotebook()
        goBackToGallery()

        openCoverEditor(of: "Cuaderno 1")
        app.buttons["Dibujo"].tap()
        app.buttons["Dibujar portada"].tap()
        XCTAssertTrue(app.buttons["Usar dibujo"].waitForExistence(timeout: 5))
        app.buttons["Cancelar dibujo"].tap()

        XCTAssertTrue(app.buttons["Dibujar portada"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Quitar dibujo"].exists)
    }

    func testExportingANotebookOpensTheShareSheetWithoutErrors() {
        openNewNotebook()
        goBackToGallery()

        let export = app.openContextMenu(on: app.buttons["Cuaderno 1"], showing: "Exportar")
        export.tap()

        XCTAssertFalse(app.alerts["Algo salió mal"].waitForExistence(timeout: 3))
        assertAppIsRunning()
    }
}
