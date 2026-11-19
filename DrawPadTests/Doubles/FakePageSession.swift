import Foundation
@testable import DrawPad

/// Hoja abierta falsa: registra lo que el cuaderno le pide.
@MainActor
final class FakePageSession: PageSession {
    let pageID: UUID
    let kind: PageKind
    let shareName: String
    private(set) var flushCount = 0
    private(set) var discardCount = 0

    init(pageID: UUID, kind: PageKind = .drawing, shareName: String) {
        self.pageID = pageID
        self.kind = kind
        self.shareName = shareName
    }

    func flushPendingSave() {
        flushCount += 1
    }

    func discardPendingSave() {
        discardCount += 1
    }
}
