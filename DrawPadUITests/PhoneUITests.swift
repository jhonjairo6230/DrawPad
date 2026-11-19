import XCTest

/// Pruebas del modo iPhone: se escriben hojas Markdown y se hacen diagramas
/// (figuras, conexiones, Mermaid); los trazos solo se leen.
///
/// Corren en el simulador de iPad con `-phoneMode`, que hace que la app se
/// comporte como en el iPhone, y con un cuaderno de ejemplo ("Cuaderno 1",
/// tres hojas: "Hola desde el iPad" en la primera y una hoja Markdown al
/// final), porque en este modo no se pueden crear cuadernos.
final class PhoneUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-phoneMode", "-uiTestingSampleNotebook"]
        app.launch()
    }

    func testTheGalleryCanImportButNotCreateOrEditNotebooks() {
        let card = app.buttons["Cuaderno 1"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Importar"].exists)
        XCTAssertFalse(app.buttons["Nuevo cuaderno"].exists)

        card.press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["Exportar"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Renombrar"].exists)
        XCTAssertFalse(app.buttons["Cambiar portada"].exists)
    }

    func testDrawingPagesOfferDiagramsButNoStrokeTools() {
        openSampleNotebook()

        XCTAssertTrue(app.staticTexts["Hola desde el iPad"].waitForExistence(timeout: 5))
        assertTitle(contains: "Hoja 1 de 3")
        for editing in ["Deshacer", "Rehacer", "Fondo", "Más", "Hojas"] {
            XCTAssertFalse(app.buttons[editing].exists, "No debería estar: \(editing)")
        }
        XCTAssertTrue(app.buttons["Compartir"].exists)
        app.buttons["Insertar"].tap()
        XCTAssertTrue(app.buttons["Figura"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Diagrama Mermaid"].exists)
        XCTAssertFalse(app.buttons["Cuadro de texto"].exists)
        XCTAssertFalse(app.buttons["Pegar"].exists)
        // Cierra el menú sin elegir nada.
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.9)).tap()

        app.buttons["Hoja siguiente"].tap()
        assertTitle(contains: "Hoja 2 de 3")
        app.buttons["Hoja anterior"].tap()
        assertTitle(contains: "Hoja 1 de 3")
    }

    func testAMarkdownPageCanBeEdited() {
        openSampleNotebook()
        app.buttons["Hoja siguiente"].tap()
        app.buttons["Hoja siguiente"].tap()
        assertTitle(contains: "Hoja 3 de 3")
        XCTAssertTrue(app.staticTexts["Hola Markdown"].waitForExistence(timeout: 10))

        app.buttons["Editar"].tap()
        let editor = app.textViews["Texto Markdown"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)).tap()
        editor.typeText("\n\n## Escrito en el iPhone\n")
        app.buttons["Ver"].tap()

        XCTAssertTrue(app.staticTexts["Escrito en el iPhone"].waitForExistence(timeout: 10))
    }

    func testPagesCanBeAddedButOnlyMarkdownOnesDeleted() {
        openSampleNotebook()

        app.buttons["Nueva hoja"].tap()
        XCTAssertTrue(app.buttons["Hoja Markdown"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Importar Markdown…"].exists)
        XCTAssertTrue(app.buttons["Hoja de dibujo"].exists)
        app.buttons["Hoja Markdown"].tap()
        assertTitle(contains: "Hoja 4 de 4")

        // Las hojas Markdown se borran; las de dibujo, no.
        app.buttons["Hojas"].tap()
        let delete = app.buttons["Eliminar esta hoja"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        app.buttons["Eliminar hoja"].firstMatch.tap()
        assertTitle(contains: "Hoja 3 de 3")

        app.buttons["Hoja anterior"].tap()
        app.buttons["Hoja anterior"].tap()
        assertTitle(contains: "Hoja 1 de 3")
        XCTAssertFalse(app.buttons["Hojas"].exists)
    }

    func testBuildingADiagramWithShapesAndAnArrow() {
        openSampleNotebook()

        insertShape("Cuadrado")
        dragElement(app.staticTexts["Cuadrado"], to: screenPoint(0.25, 0.6))
        app.buttons["Editar texto"].tap()
        typeInEditor("App")
        XCTAssertTrue(app.staticTexts["Cuadrado: App"].waitForExistence(timeout: 5))

        insertShape("Cilindro")
        dragElement(app.staticTexts["Cilindro"], to: screenPoint(0.7, 0.6))
        app.buttons["Girar"].tap()

        app.staticTexts["Cuadrado: App"].tap()
        app.buttons["Conectar"].tap()
        app.buttons["Con flecha"].tap()
        XCTAssertTrue(app.staticTexts["Toca el elemento de destino"].waitForExistence(timeout: 5))
        app.staticTexts["Cilindro"].tap()
        XCTAssertTrue(app.staticTexts["Conexión seleccionada"].waitForExistence(timeout: 5))
        app.buttons["Listo"].tap()

        // Se guardó: sigue ahí al volver a abrir el cuaderno.
        app.navigationBars.buttons["Cuadernos"].tap()
        openSampleNotebook()
        XCTAssertTrue(app.staticTexts["Cuadrado: App"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Hola desde el iPad"].exists)
    }

    func testInsertingAMermaidDiagram() {
        openSampleNotebook()

        app.buttons["Insertar"].tap()
        let mermaid = app.buttons["Diagrama Mermaid"]
        XCTAssertTrue(mermaid.waitForExistence(timeout: 5))
        mermaid.tap()
        let insert = app.buttons["Confirmar diagrama"]
        XCTAssertTrue(insert.waitForExistence(timeout: 10))
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: insert)
        XCTAssertEqual(XCTWaiter().wait(for: [enabled], timeout: 20), .completed, "Mermaid no dibujó la plantilla")
        insert.tap()

        XCTAssertTrue(app.images["Diagrama Mermaid"].waitForExistence(timeout: 10))
        app.buttons["Listo"].tap()
        _ = app.wait(for: .notRunning, timeout: 2)
        XCTAssertEqual(app.state, .runningForeground, "La app se cerró")
    }

    func testScrollingAndZoomingAPageDoesNotDrawOrCrash() {
        openSampleNotebook()
        let window = app.windows.firstMatch

        window.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.4))
            .press(forDuration: 0.1, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.6)))
        window.pinch(withScale: 2, velocity: 2)
        window.pinch(withScale: 0.5, velocity: -2)

        // El zoom termina con una animación: se espera a que se asiente.
        XCTAssertTrue(app.staticTexts["Hola desde el iPad"].waitForExistence(timeout: 5))
        _ = app.wait(for: .notRunning, timeout: 2)
        XCTAssertEqual(app.state, .runningForeground, "La app se cerró")
    }

    // MARK: - Utilidades

    private func openSampleNotebook() {
        let card = app.buttons["Cuaderno 1"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        XCTAssertTrue(app.buttons["Compartir"].waitForExistence(timeout: 5))
    }

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

    private func screenPoint(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
    }

    /// Espera a que el título de la barra diga, por ejemplo, "Hoja 2 de 2".
    private func assertTitle(contains text: String, file: StaticString = #filePath, line: UInt = #line) {
        // Es texto en las hojas de dibujo y un botón (menú) en las Markdown.
        let title = app.navigationBars.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5), "El título no muestra \"\(text)\"", file: file, line: line)
    }
}
