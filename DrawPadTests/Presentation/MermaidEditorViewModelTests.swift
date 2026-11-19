import XCTest
@testable import DrawPad

@MainActor
final class MermaidEditorViewModelTests: XCTestCase {
    private var preview: FakeMermaidPreview!

    override func setUp() async throws {
        preview = FakeMermaidPreview()
    }

    private func makeViewModel(_ source: String = "flowchart LR\n A --> B", theme: CanvasTheme = .light) -> MermaidEditorViewModel {
        MermaidEditorViewModel(source: source, theme: theme, preview: preview, renderDelay: .milliseconds(10))
    }

    func testOnAppearDrawsTheInitialSourceWithThePageTheme() async {
        let viewModel = makeViewModel(theme: .dark)

        await viewModel.onAppear()

        XCTAssertEqual(preview.rendered.map(\.source), ["flowchart LR\n A --> B"])
        XCTAssertEqual(preview.rendered.map(\.theme), [.dark])
        XCTAssertTrue(viewModel.hasDiagram)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testTypingRedrawsOnceAfterAPause() async throws {
        let viewModel = makeViewModel()
        await viewModel.onAppear()

        viewModel.updateSource("graph TD")
        viewModel.updateSource("graph TD\n A")
        viewModel.updateSource("graph TD\n A --> B")
        try await waitUntil { self.preview.rendered.count == 2 }
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(preview.rendered.map(\.source), ["flowchart LR\n A --> B", "graph TD\n A --> B"])
        XCTAssertEqual(viewModel.source, "graph TD\n A --> B")
    }

    func testAMermaidErrorIsShownAndThereIsNoDiagram() async {
        preview.outcome = .failed("Parse error on line 2")
        let viewModel = makeViewModel()

        await viewModel.onAppear()

        XCTAssertFalse(viewModel.hasDiagram)
        XCTAssertEqual(viewModel.errorMessage, "Parse error on line 2")
    }

    func testAnEmptySourceIsNotSentToMermaid() async {
        let viewModel = makeViewModel("   ")

        await viewModel.onAppear()

        XCTAssertTrue(preview.rendered.isEmpty)
        XCTAssertFalse(viewModel.hasDiagram)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testFinishReturnsTheTrimmedSourceAndTheImage() async throws {
        let viewModel = makeViewModel()
        await viewModel.onAppear()
        viewModel.updateSource("  graph TD\n A --> B  ")

        let finished = await viewModel.finish()
        let result = try XCTUnwrap(finished)

        XCTAssertEqual(result.source, "graph TD\n A --> B")
        XCTAssertEqual(result.snapshot.image, Data("png".utf8))
        // finish dibuja el último texto sin esperar la pausa.
        XCTAssertEqual(preview.rendered.last?.source, "graph TD\n A --> B")
    }

    func testFinishWithAnErrorReturnsNothing() async {
        let viewModel = makeViewModel()
        preview.outcome = .failed("Syntax error")

        let result = await viewModel.finish()

        XCTAssertNil(result)
        XCTAssertEqual(viewModel.errorMessage, "Syntax error")
    }

    func testFinishReportsAnImageThatCouldNotBeMade() async {
        let viewModel = makeViewModel()
        preview.snapshotResult = .failure(.invalidDiagram("no se pudo convertir en imagen"))

        let result = await viewModel.finish()

        XCTAssertNil(result)
        XCTAssertEqual(viewModel.errorMessage, DrawingError.invalidDiagram("no se pudo convertir en imagen").errorDescription)
    }

    private func waitUntil(_ condition: @escaping () -> Bool) async throws {
        for _ in 0..<200 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("La condición no se cumplió a tiempo")
    }
}
