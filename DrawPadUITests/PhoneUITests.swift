import XCTest

/// Pruebas del modo iPhone: las hojas de dibujo solo se leen; las Markdown
/// se escriben.
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

    func testDrawingPagesCanBeReadPageByPageButNotEdited() {
        openSampleNotebook()

        XCTAssertTrue(app.staticTexts["Hola desde el iPad"].waitForExistence(timeout: 5))
        assertTitle(contains: "Hoja 1 de 3")
        for editing in ["Insertar", "Deshacer", "Rehacer", "Fondo", "Más", "Hojas"] {
            XCTAssertFalse(app.buttons[editing].exists, "No debería estar: \(editing)")
        }
        XCTAssertTrue(app.buttons["Compartir"].exists)

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

    func testOnlyMarkdownPagesCanBeAddedAndDeleted() {
        openSampleNotebook()

        app.buttons["Nueva hoja"].tap()
        XCTAssertTrue(app.buttons["Hoja Markdown"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Importar Markdown…"].exists)
        XCTAssertFalse(app.buttons["Hoja de dibujo"].exists)
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

    /// Espera a que el título de la barra diga, por ejemplo, "Hoja 2 de 2".
    private func assertTitle(contains text: String, file: StaticString = #filePath, line: UInt = #line) {
        // Es texto en las hojas de dibujo y un botón (menú) en las Markdown.
        let title = app.navigationBars.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5), "El título no muestra \"\(text)\"", file: file, line: line)
    }
}
