import XCTest
@testable import DrawPad

@MainActor
final class CoverDrawingViewModelTests: XCTestCase {
    private var canvas: FakeDrawingCanvas!
    private var preferences: CanvasPreferences!

    override func setUp() async throws {
        canvas = FakeDrawingCanvas()
        preferences = CanvasPreferences()
    }

    private func makeViewModel(initialDrawing: CoverDrawing? = nil, color: CoverColor = .teal) -> CoverDrawingViewModel {
        CoverDrawingViewModel(canvas: canvas, initialDrawing: initialDrawing, color: color, preferences: preferences)
    }

    func testOnAppearPaintsThePaperWithTheCoverColor() {
        let viewModel = makeViewModel(color: .orange)

        viewModel.onAppear()

        XCTAssertEqual(canvas.paperColor, .orange)
        XCTAssertEqual(canvas.isFingerDrawingEnabled, false)
        XCTAssertTrue(canvas.strokes.isEmpty)
    }

    func testOnAppearLoadsTheCurrentDrawingToKeepEditingIt() {
        let current = CoverDrawing(strokesData: Data("trazos".utf8), imageData: Data("png".utf8))
        let viewModel = makeViewModel(initialDrawing: current)

        viewModel.onAppear()

        XCTAssertEqual(canvas.strokes, Data("trazos".utf8))
    }

    func testOnAppearShowsAnAlertWhenTheDrawingCannotBeRead() {
        canvas.loadError = DrawingError.storageFailed
        let viewModel = makeViewModel(initialDrawing: CoverDrawing(strokesData: Data("x".utf8), imageData: Data()))

        viewModel.onAppear()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: DrawingError.storageFailed))
    }

    func testFinishReturnsTheStrokesAndTheTransparentImage() {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        canvas.simulateStroke(Data("dibujo".utf8))

        let drawing = viewModel.finish()

        XCTAssertEqual(drawing, CoverDrawing(strokesData: Data("dibujo".utf8), imageData: Data("portada".utf8)))
    }

    func testFinishWithoutStrokesReturnsNoDrawing() {
        let viewModel = makeViewModel(initialDrawing: CoverDrawing(strokesData: Data("x".utf8), imageData: Data("y".utf8)))
        viewModel.onAppear()
        viewModel.clear()

        XCTAssertNil(viewModel.finish())
        XCTAssertEqual(canvas.clearCount, 1)
    }

    func testToolsAreForwardedToTheCanvasAndFingerDrawingIsShared() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        viewModel.undo()
        viewModel.redo()
        viewModel.toggleFingerDrawing()

        XCTAssertEqual(canvas.undoCount, 1)
        XCTAssertEqual(canvas.redoCount, 1)
        XCTAssertEqual(canvas.isFingerDrawingEnabled, true)
        XCTAssertTrue(preferences.isFingerDrawingEnabled)
    }
}
