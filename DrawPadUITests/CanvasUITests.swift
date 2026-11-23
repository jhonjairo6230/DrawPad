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
        app.buttons["Dibujar portada"].tap()
        XCTAssertTrue(app.buttons["Usar dibujo"].waitForExistence(timeout: 5))
        app.buttons["Dibujar con el dedo"].tap()
        canvasPoint(0.45, 0.4).press(forDuration: 0.1, thenDragTo: canvasPoint(0.55, 0.55))
        app.buttons["Usar dibujo"].tap()

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

        let card = app.buttons["Cuaderno 1"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.press(forDuration: 1.2)
        let export = app.buttons["Exportar"]
        XCTAssertTrue(export.waitForExistence(timeout: 5))
        export.tap()

        XCTAssertFalse(app.alerts["Algo salió mal"].waitForExistence(timeout: 3))
        assertAppIsRunning()
    }

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
        enableFingerDrawing()
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

    /// Mantiene pulsada la tarjeta de un cuaderno y elige "Cambiar portada".
    private func openCoverEditor(of notebook: String) {
        let card = app.buttons[notebook]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.press(forDuration: 1.2)
        let action = app.buttons["Cambiar portada"]
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        action.tap()
        XCTAssertTrue(app.buttons["Guardar"].waitForExistence(timeout: 5))
    }

    /// Abre el menú "Más" del lienzo y elige una acción.
    private func chooseMoreAction(_ title: String) {
        chooseMenuAction(title, inMenu: "Más")
    }

    /// Abre el menú "Insertar" del lienzo y elige una acción.
    private func chooseInsertAction(_ title: String) {
        chooseMenuAction(title, inMenu: "Insertar")
    }

    private func chooseMenuAction(_ title: String, inMenu menu: String) {
        app.buttons[menu].tap()
        // Un interruptor dentro de un menú puede ser un botón o un switch
        // según la versión de iOS: se busca por nombre, sea del tipo que sea.
        let action = app.descendants(matching: .any).matching(identifier: title).firstMatch
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        action.tap()
    }

    /// Menú "Insertar" → "Figura" → la figura pedida.
    private func insertShape(_ title: String) {
        app.buttons["Insertar"].tap()
        let shapes = app.buttons["Figura"]
        XCTAssertTrue(shapes.waitForExistence(timeout: 5))
        shapes.tap()
        let shape = app.buttons[title]
        XCTAssertTrue(shape.waitForExistence(timeout: 5))
        shape.tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
    }

    /// Arrastra un elemento (en el modo de mover) hasta un punto de la pantalla.
    private func dragElement(_ element: XCUIElement, to point: XCUICoordinate) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.2, thenDragTo: point)
    }

    /// Escribe en el editor de texto abierto y guarda.
    private func typeInEditor(_ text: String) {
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(text)
        app.buttons["Guardar"].tap()
    }

    /// "Dibujar con el dedo" está en el menú "Más".
    private func enableFingerDrawing() {
        chooseMoreAction("Dibujar con el dedo")
    }

    /// Inserta un cuadro de texto escribiendo con el teclado.
    private func insertTextBox(_ text: String) {
        chooseInsertAction("Cuadro de texto")
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(text)
        app.buttons["Guardar"].tap()
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5))
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
