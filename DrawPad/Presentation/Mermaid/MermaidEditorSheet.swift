import SwiftUI

/// Editor de un diagrama de Mermaid: el texto arriba, la vista previa abajo y
/// el error de Mermaid, si lo hay, entre los dos.
struct MermaidEditorSheet: View {
    let request: MermaidEditorRequest
    let module: MermaidEditorModule
    /// Texto definitivo e imagen del diagrama.
    let onCommit: (String, MermaidSnapshot) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isFinishing = false

    private var viewModel: MermaidEditorViewModel { module.viewModel }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: Binding(
                    get: { viewModel.source },
                    set: { viewModel.updateSource($0) }
                ))
                .font(.system(.body, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .frame(minHeight: 160, maxHeight: 260)
                .overlay { RoundedRectangle(cornerRadius: 8).stroke(.quaternary) }
                .accessibilityLabel("Código Mermaid")

                status

                MermaidPreviewView(preview: module.preview)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityIdentifier("Vista previa")
            }
            .padding(16)
            .navigationTitle(request.isNew ? "Nuevo diagrama" : "Editar diagrama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(request.isNew ? "Insertar" : "Guardar") { finish() }
                        .disabled(isFinishing || viewModel.isRendering || !viewModel.hasDiagram)
                        // Debajo está el menú "Insertar" del lienzo: otro identificador
                        // evita confundirlos.
                        .accessibilityIdentifier("Confirmar diagrama")
                }
            }
            .task { await viewModel.onAppear() }
        }
    }

    @ViewBuilder
    private var status: some View {
        if let error = viewModel.errorMessage {
            Text("Error en el diagrama: \(error)")
                .font(.footnote)
                .foregroundStyle(.red)
                .lineLimit(4)
        } else if viewModel.isRendering {
            Text("Dibujando…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            Link("Sintaxis de Mermaid", destination: URL(string: "https://mermaid.js.org/intro/syntax-reference.html")!)
                .font(.footnote)
        }
    }

    private func finish() {
        isFinishing = true
        Task {
            if let result = await viewModel.finish() {
                onCommit(result.source, result.snapshot)
                dismiss()
            }
            isFinishing = false
        }
    }
}

/// Crea el editor **una sola vez** por petición y lo muestra.
///
/// SwiftUI puede volver a evaluar el contenido de una hoja varias veces; si
/// el editor se creara ahí, cada vez nacería otra vista web y se perdería lo
/// escrito. Aquí se guarda en `@State` y se crea al aparecer.
struct MermaidEditorHost: View {
    let request: MermaidEditorRequest
    let theme: CanvasTheme
    let makeEditor: (String, CanvasTheme) -> MermaidEditorModule
    let onCommit: (String, MermaidSnapshot) -> Void

    @State private var module: MermaidEditorModule?

    var body: some View {
        if let module {
            MermaidEditorSheet(request: request, module: module, onCommit: onCommit)
        } else {
            ProgressView()
                .onAppear { module = makeEditor(request.source, theme) }
        }
    }
}
