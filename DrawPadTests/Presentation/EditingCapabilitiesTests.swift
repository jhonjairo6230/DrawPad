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

    func testOnTheIPhoneNotebooksMarkdownAndDiagramsCanBeChangedButNotStrokes() {
        let editing = EditingCapabilities.phone

        XCTAssertTrue(editing.canManageNotebooks)
        XCTAssertFalse(editing.canDraw)
        XCTAssertTrue(editing.canEditDiagrams)
        XCTAssertTrue(editing.canWriteMarkdown)
        XCTAssertTrue(editing.canAddDrawingPages)
        XCTAssertTrue(editing.canEditDrawingPages)
        XCTAssertTrue(editing.canAddPages)
        XCTAssertFalse(editing.canDeletePage(of: .drawing))
        XCTAssertTrue(editing.canDeletePage(of: .markdown))
    }

    func testTheDrawnCoverIsOfferedOnlyWhereYouCanDraw() {
        XCTAssertEqual(EditingCapabilities.full.coverStyles(current: .plain), CoverStyle.allCases)
        XCTAssertFalse(EditingCapabilities.phone.coverStyles(current: .plain).contains(.drawn))
        XCTAssertEqual(EditingCapabilities.phone.coverStyles(current: .label), [.plain, .label, .spine])
    }

    func testADrawnCoverMadeOnTheIPadIsKeptOnTheIPhone() {
        XCTAssertTrue(EditingCapabilities.phone.coverStyles(current: .drawn).contains(.drawn))
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
