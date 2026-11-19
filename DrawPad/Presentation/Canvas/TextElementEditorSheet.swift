import SwiftUI

/// Hoja para escribir el texto de un cuadro con el teclado del iPad.
///
/// Trabaja sobre una copia: nada cambia en la hoja hasta tocar "Guardar".
struct TextElementEditorSheet: View {
    let request: TextEditorRequest
    let onSave: (String) -> Void

    @State private var text: String
    @FocusState private var isEditorFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(request: TextEditorRequest, onSave: @escaping (String) -> Void) {
        self.request = request
        self.onSave = onSave
        _text = State(initialValue: request.text)
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .font(.title3)
                .focused($isEditorFocused)
                .padding(16)
                .accessibilityLabel("Texto")
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            onSave(text)
                            dismiss()
                        }
                        // Una figura puede quedarse sin texto; un cuadro de texto no.
                        .disabled(isBlank && !request.isShapeLabel)
                    }
                }
                // Con el teclado ya abierto se puede empezar a escribir sin tocar nada.
                .onAppear { isEditorFocused = true }
        }
    }

    private var navigationTitle: String {
        if request.isShapeLabel { return "Texto de la figura" }
        return request.isNew ? "Nuevo texto" : "Editar texto"
    }

    private var isBlank: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
