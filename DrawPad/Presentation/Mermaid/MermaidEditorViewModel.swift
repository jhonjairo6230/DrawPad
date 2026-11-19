import Foundation
import Observation

/// Estado del editor de diagramas de Mermaid (patrón MVVM).
///
/// Mientras se escribe, vuelve a dibujar la vista previa cuando el usuario
/// para de teclear un momento (`renderDelay`), para no dibujar en cada
/// tecla. Al terminar (``finish()``) devuelve el texto y la imagen; no guarda
/// nada: eso lo decide quien abrió el editor.
@MainActor
@Observable
final class MermaidEditorViewModel {
    private(set) var source: String
    /// Mensaje de error de Mermaid, o `nil` si el diagrama se dibujó bien.
    private(set) var errorMessage: String?
    private(set) var isRendering = false
    /// `true` si la vista previa muestra un diagrama válido.
    private(set) var hasDiagram = false

    private let theme: CanvasTheme
    private let preview: MermaidPreview
    private let renderDelay: Duration

    @ObservationIgnored private var pendingRender: Task<Void, Never>?
    @ObservationIgnored private var hasAppeared = false

    init(source: String, theme: CanvasTheme, preview: MermaidPreview, renderDelay: Duration = .milliseconds(400)) {
        self.source = source
        self.theme = theme
        self.preview = preview
        self.renderDelay = renderDelay
    }

    /// Dibuja el texto inicial.
    func onAppear() async {
        guard !hasAppeared else { return }
        hasAppeared = true
        await render()
    }

    /// El usuario cambió el texto: se dibuja cuando deje de escribir.
    func updateSource(_ newSource: String) {
        guard newSource != source else { return }
        source = newSource
        pendingRender?.cancel()
        let delay = renderDelay
        pendingRender = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return // Llegó otra tecla antes.
            }
            await self?.render()
        }
    }

    /// Dibuja ya el texto actual (sin esperar) y, si salió bien, devuelve el
    /// texto y su imagen. Si no, deja el error a la vista y devuelve `nil`.
    func finish() async -> (source: String, snapshot: MermaidSnapshot)? {
        pendingRender?.cancel()
        pendingRender = nil
        await render()
        guard hasDiagram else { return nil }
        do {
            let snapshot = try await preview.snapshot()
            return (source.trimmingCharacters(in: .whitespacesAndNewlines), snapshot)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }

    private func render() async {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            hasDiagram = false
            errorMessage = "Escribe un diagrama de Mermaid."
            return
        }
        isRendering = true
        let outcome = await preview.render(source: trimmed, theme: theme)
        isRendering = false
        switch outcome {
        case .rendered:
            hasDiagram = true
            errorMessage = nil
        case .failed(let message):
            hasDiagram = false
            errorMessage = message
        }
    }
}
