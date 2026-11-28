import XCTest

/// Base de las pruebas de interfaz del iPad: arranca la app y reúne las
/// utilidades que usan todas (abrir un cuaderno, menús, tocar el lienzo…).
///
/// Las pruebas están repartidas en varias clases por tema, para que cada
/// archivo sea corto (ver docs/adr/0025-pruebas-mas-rapidas.md).
///
/// En el simulador todo toque es un "dedo" (no hay Apple Pencil), así que
/// estas pruebas cubren justo lo que las unitarias no pueden: que PencilKit,
/// la navegación entre cuadernos y hojas y la base de datos aguanten toques
/// reales sin cerrarse.
///
/// Cada prueba arranca con `-uiTesting`: una base de datos vacía en memoria.
class DrawPadUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    // MARK: - Utilidades

    /// Dibuja algo y abre la hoja de compartir. La hoja es del sistema: basta
    /// con comprobar que la app sigue viva y no mostró un error.
    func shareDrawing(option: String) {
        openNewNotebook()
        enableFingerDrawing()
        dragOnCanvas()

        app.buttons["Compartir"].tap()
        app.buttons[option].tap()

        XCTAssertFalse(app.alerts["Algo salió mal"].waitForExistence(timeout: 3))
        assertAppIsRunning()
    }

    func chooseBackground(_ title: String) {
        app.buttons["Fondo"].tap()
        // Según la versión de iOS, un interruptor dentro de un menú puede ser
        // un botón o un switch: se busca por nombre, sea del tipo que sea.
        let option = app.descendants(matching: .any).matching(identifier: title).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
    }

    func openNewNotebook() {
        let newNotebook = app.buttons["Nuevo cuaderno"]
        XCTAssertTrue(newNotebook.waitForExistence(timeout: 5))
        newNotebook.tap()
        XCTAssertTrue(app.buttons["Compartir"].waitForExistence(timeout: 5))
    }

    func goBackToGallery() {
        app.navigationBars.buttons["Cuadernos"].tap()
        XCTAssertTrue(app.buttons["Nuevo cuaderno"].waitForExistence(timeout: 5))
    }

    /// Mantiene pulsada la tarjeta de un cuaderno y elige "Cambiar portada".
    func openCoverEditor(of notebook: String) {
        app.openContextMenu(on: app.buttons[notebook], showing: "Cambiar portada").tap()
        XCTAssertTrue(app.buttons["Guardar"].waitForExistence(timeout: 5))
    }

    /// Abre el menú "Más" del lienzo y elige una acción.
    func chooseMoreAction(_ title: String) {
        chooseMenuAction(title, inMenu: "Más")
    }

    /// Abre el menú "Insertar" del lienzo y elige una acción.
    func chooseInsertAction(_ title: String) {
        chooseMenuAction(title, inMenu: "Insertar")
    }

    func chooseMenuAction(_ title: String, inMenu menu: String) {
        app.buttons[menu].tap()
        // Un interruptor dentro de un menú puede ser un botón o un switch
        // según la versión de iOS: se busca por nombre, sea del tipo que sea.
        let action = app.descendants(matching: .any).matching(identifier: title).firstMatch
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        action.tap()
    }

    /// Menú "Insertar" → "Figura" → la figura pedida.
    func insertShape(_ title: String) {
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
    func dragElement(_ element: XCUIElement, to point: XCUICoordinate) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.2, thenDragTo: point)
    }

    /// Escribe en el editor de texto abierto y guarda.
    func typeInEditor(_ text: String) {
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(text)
        app.buttons["Guardar"].tap()
    }

    /// "Dibujar con el dedo" está en el menú "Más".
    func enableFingerDrawing() {
        chooseMoreAction("Dibujar con el dedo")
    }

    /// Inserta un cuadro de texto escribiendo con el teclado.
    func insertTextBox(_ text: String) {
        chooseInsertAction("Cuadro de texto")
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(text)
        app.buttons["Guardar"].tap()
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5))
    }

    /// Abre el menú de hojas (el título de la barra) y elige una acción.
    func choosePageAction(_ title: String) {
        app.buttons["Hojas"].tap()
        let action = app.buttons[title]
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        action.tap()
    }

    /// Espera a que el título de la barra diga, por ejemplo, "Hoja 2 de 3".
    func assertPageLabel(contains text: String, file: StaticString = #filePath, line: UInt = #line) {
        let label = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: label, object: app.buttons["Hojas"])
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "El título no muestra \"\(text)\"", file: file, line: line)
    }

    func canvasPoint(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
    }

    func tapCanvas() {
        canvasPoint(0.5, 0.5).tap()
    }

    /// Un trazo (con "dibujar con el dedo") o un desplazamiento (sin él).
    /// Vertical: desde iOS 26, deslizar a la derecha en cualquier punto de la
    /// pantalla es "volver", y sin dedo que dibuje a veces gana ese gesto.
    func dragOnCanvas() {
        canvasPoint(0.45, 0.35).press(forDuration: 0.1, thenDragTo: canvasPoint(0.5, 0.65))
    }

    /// Desde el editor de portada (estilo "Dibujo"): abre "Dibujar portada",
    /// hace un trazo con el dedo y toca "Usar dibujo".
    ///
    /// A veces el primer trazo justo después de activar "Dibujar con el dedo"
    /// no llega al lienzo; la portada queda vacía y el editor vuelve a ofrecer
    /// "Dibujar portada". Entonces se dibuja otra vez, una sola vez. "Dibujar
    /// con el dedo" se recuerda entre aperturas: solo se toca la primera.
    func drawCover(file: StaticString = #filePath, line: UInt = #line) {
        for attempt in 0..<2 {
            app.buttons["Dibujar portada"].tap()
            XCTAssertTrue(app.buttons["Usar dibujo"].waitForExistence(timeout: 5), file: file, line: line)
            if attempt == 0 { app.buttons["Dibujar con el dedo"].tap() }
            canvasPoint(0.45, 0.4).press(forDuration: 0.1, thenDragTo: canvasPoint(0.55, 0.55))
            app.buttons["Usar dibujo"].tap()
            if app.buttons["Editar dibujo"].waitForExistence(timeout: 5) { return }
        }
        XCTFail("El trazo no llegó a la portada", file: file, line: line)
    }

    func assertAppIsRunning(file: StaticString = #filePath, line: UInt = #line) {
        // Deja tiempo a que un cierre diferido llegue a ocurrir.
        _ = app.wait(for: .notRunning, timeout: 2)
        XCTAssertEqual(app.state, .runningForeground, "La app se cerró", file: file, line: line)
    }
}
