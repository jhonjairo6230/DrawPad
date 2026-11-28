import XCTest

/// Pruebas de interfaz del iPad: figuras de diagrama, conexiones y diagramas de
/// Mermaid.
final class DiagramUITests: DrawPadUITestCase {
    // MARK: - Figuras de diagrama

    func testBuildingASmallArchitectureDiagram() {
        openNewNotebook()

        // Un servicio a la izquierda…
        insertShape("Cuadrado")
        dragElement(app.staticTexts["Cuadrado"], to: canvasPoint(0.25, 0.45))
        app.buttons["Editar texto"].tap()
        typeInEditor("API")
        XCTAssertTrue(app.staticTexts["Cuadrado: API"].waitForExistence(timeout: 5))

        // …y una cola de mensajes (cilindro acostado) a la derecha.
        insertShape("Cilindro")
        dragElement(app.staticTexts["Cilindro"], to: canvasPoint(0.7, 0.45))
        app.buttons["Girar"].tap()
        app.buttons["Editar texto"].tap()
        typeInEditor("Kafka")
        XCTAssertTrue(app.staticTexts["Cilindro: Kafka"].waitForExistence(timeout: 5))

        // Flecha de la API a la cola.
        app.staticTexts["Cuadrado: API"].tap()
        app.buttons["Conectar"].tap()
        app.buttons["Con flecha"].tap()
        XCTAssertTrue(app.staticTexts["Toca el elemento de destino"].waitForExistence(timeout: 5))
        app.staticTexts["Cilindro: Kafka"].tap()
        XCTAssertTrue(app.staticTexts["Conexión seleccionada"].waitForExistence(timeout: 5))

        // Mover una figura con la flecha puesta no rompe nada.
        dragElement(app.staticTexts["Cilindro: Kafka"], to: canvasPoint(0.7, 0.7))
        app.buttons["Listo"].tap()

        goBackToGallery()
        app.buttons["Cuaderno 1"].tap()
        XCTAssertTrue(app.staticTexts["Cuadrado: API"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cilindro: Kafka"].exists)
        assertAppIsRunning()
    }

    func testEveryShapeCanBeInsertedAndDeleted() {
        openNewNotebook()

        for shape in ["Cuadrado", "Círculo", "Rombo", "Cilindro"] {
            insertShape(shape)
            XCTAssertTrue(app.staticTexts[shape].waitForExistence(timeout: 5))
            app.buttons["Eliminar"].tap()
            XCTAssertFalse(app.staticTexts[shape].waitForExistence(timeout: 2))
        }
        app.buttons["Listo"].tap()
        assertAppIsRunning()
    }

    func testCancellingAConnectionLeavesTheShapeSelected() {
        openNewNotebook()
        insertShape("Rombo")

        app.buttons["Conectar"].tap()
        app.buttons["Con línea"].tap()
        app.buttons["Cancelar conexión"].tap()

        XCTAssertTrue(app.staticTexts["Arrastra para mover"].waitForExistence(timeout: 5))
        assertAppIsRunning()
    }

    // MARK: - Diagramas de Mermaid

    func testInsertingAMermaidDiagramFromTheTemplate() {
        openNewNotebook()

        chooseInsertAction("Diagrama Mermaid")
        let insert = app.buttons["Confirmar diagrama"]
        XCTAssertTrue(insert.waitForExistence(timeout: 10))
        // Mermaid tarda un poco en dibujar la plantilla: el botón se activa después.
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: insert)
        XCTAssertEqual(XCTWaiter().wait(for: [enabled], timeout: 20), .completed, "Mermaid no dibujó la plantilla")
        insert.tap()

        XCTAssertTrue(app.images["Diagrama Mermaid"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Editar diagrama"].exists)
        app.buttons["Listo"].tap()
        assertAppIsRunning()
    }

    func testAMermaidSyntaxErrorIsShownInTheEditor() {
        openNewNotebook()

        chooseInsertAction("Diagrama Mermaid")
        let editor = app.textViews["Código Mermaid"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
        editor.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 200))
        editor.typeText("flowchart LR\n  A -->")

        let error = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Error en el diagrama")).firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["Confirmar diagrama"].isEnabled)
        app.buttons["Cancelar"].firstMatch.tap()
        assertAppIsRunning()
    }
}
