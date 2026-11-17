import SwiftUI

/// Hoja para elegir la tapa de un cuaderno: vista previa, estilo y color.
///
/// Trabaja sobre una copia (`cover`): nada cambia hasta tocar "Guardar".
struct CoverEditorSheet: View {
    let title: String
    let onSave: (NotebookCover) -> Void

    @State private var cover: NotebookCover
    @Environment(\.dismiss) private var dismiss

    private let swatchColumns = [GridItem(.adaptive(minimum: 52), spacing: 16)]

    init(title: String, cover: NotebookCover, onSave: @escaping (NotebookCover) -> Void) {
        self.title = title
        self.onSave = onSave
        _cover = State(initialValue: cover)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    NotebookCoverView(title: title, cover: cover)
                        .frame(maxHeight: 260)

                    Picker("Estilo", selection: $cover.style) {
                        ForEach(CoverStyle.allCases, id: \.self) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)

                    LazyVGrid(columns: swatchColumns, spacing: 16) {
                        ForEach(CoverColor.allCases, id: \.self) { color in
                            swatch(color)
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Portada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(cover)
                        dismiss()
                    }
                }
            }
        }
    }

    private func swatch(_ color: CoverColor) -> some View {
        let isSelected = cover.color == color
        return Button { cover.color = color } label: {
            Circle()
                .fill(color.color)
                .frame(width: 44, height: 44)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .padding(4)
                .overlay {
                    Circle().stroke(isSelected ? Color.primary : .clear, lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(color.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
