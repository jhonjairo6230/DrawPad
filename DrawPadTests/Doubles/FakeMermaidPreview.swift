import Foundation
@testable import DrawPad

/// Motor de Mermaid falso: devuelve lo que la prueba diga y recuerda qué se
/// le pidió dibujar.
@MainActor
final class FakeMermaidPreview: MermaidPreview {
    var outcome: MermaidPreviewOutcome = .rendered(CGSize(width: 300, height: 200))
    var snapshotResult: Result<MermaidSnapshot, DrawingError> = .success(
        MermaidSnapshot(image: Data("png".utf8), size: CGSize(width: 300, height: 200))
    )
    private(set) var rendered: [(source: String, theme: CanvasTheme)] = []

    func render(source: String, theme: CanvasTheme) async -> MermaidPreviewOutcome {
        rendered.append((source, theme))
        return outcome
    }

    func snapshot() async throws -> MermaidSnapshot {
        try snapshotResult.get()
    }
}
