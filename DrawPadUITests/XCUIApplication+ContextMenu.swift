import XCTest

extension XCUIApplication {
    /// Mantiene pulsado `element` hasta que su menú contextual muestra
    /// `action`, y devuelve ese botón.
    ///
    /// Si la pulsación llega mientras la pantalla aún termina una animación
    /// (por ejemplo, al volver a la galería), iOS a veces no abre el menú. Se
    /// repite una vez, como haría una persona; si tampoco abre, la prueba
    /// falla.
    @discardableResult
    func openContextMenu(
        on element: XCUIElement,
        showing action: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
        let button = buttons[action]
        for _ in 0..<2 {
            element.press(forDuration: 1.2)
            if button.waitForExistence(timeout: 5) { return button }
        }
        XCTFail("El menú contextual no muestra \"\(action)\"", file: file, line: line)
        return button
    }
}
