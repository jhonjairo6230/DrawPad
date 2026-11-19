import XCTest
@testable import DrawPad

final class EditingCapabilitiesTests: XCTestCase {
    func testOnTheIPadEverythingCanBeChanged() {
        let editing = EditingCapabilities.full

        XCTAssertTrue(editing.canManageNotebooks)
        XCTAssertTrue(editing.canEditDiagrams)
        XCTAssertTrue(editing.canAddPages)
        XCTAssertTrue(editing.canDeletePage(of: .drawing))
        XCTAssertTrue(editing.canDeletePage(of: .markdown))
    }

    func testOnTheIPhoneMarkdownAndDiagramsCanBeChangedButNotStrokes() {
        let editing = EditingCapabilities.phone

        XCTAssertFalse(editing.canManageNotebooks)
        XCTAssertFalse(editing.canDraw)
        XCTAssertTrue(editing.canEditDiagrams)
        XCTAssertTrue(editing.canWriteMarkdown)
        XCTAssertTrue(editing.canAddDrawingPages)
        XCTAssertTrue(editing.canEditDrawingPages)
        XCTAssertTrue(editing.canAddPages)
        XCTAssertFalse(editing.canDeletePage(of: .drawing))
        XCTAssertTrue(editing.canDeletePage(of: .markdown))
    }

    func testWithNothingAllowedNoPageCanBeAdded() {
        let editing = EditingCapabilities(
            canManageNotebooks: false, canDraw: false, canEditDiagrams: false, canWriteMarkdown: false
        )

        XCTAssertFalse(editing.canAddPages)
        XCTAssertFalse(editing.canEditDrawingPages)
        XCTAssertFalse(editing.canDeletePage(of: .markdown))
    }
}
