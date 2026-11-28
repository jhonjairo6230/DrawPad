import SwiftUI

/// Hoja para elegir la tapa de un cuaderno: vista previa, estilo, color y,
/// con el estilo "Dibujo", el dibujo hecho a mano.
///
/// Trabaja sobre una copia (`cover`): nada cambia hasta tocar "Guardar",
/// tampoco el dibujo. Sin `canDraw` (iPhone) no se dibuja la portada: no se
/// ofrece el estilo "Dibujo" (salvo que ya lo tenga, y entonces se conserva).
struct CoverEditorSheet: View {
    let title: String
    /// Monta la pantalla de dibujar a partir del dibujo y el color actuales
    /// (la da ``AppContainer``).
    let makeCoverDrawing: (CoverDrawing?, CoverColor) -> CoverDrawingModule
    let onSave: (NotebookCover) -> Void

    @State private var cover: NotebookCover
    @State private var drawingModule: CoverDrawingModule?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editing) private var editing
    /// Estilo con el que se abrió, para decidir si se ofrece "Dibujo".
    private let originalStyle: CoverStyle

    private let swatchColumns = [GridItem(.adaptive(minimum: 52), spacing: 16)]

    init(
        title: String,
        cover: NotebookCover,
        makeCoverDrawing: @escaping (CoverDrawing?, CoverColor) -> CoverDrawingModule,
        onSave: @escaping (NotebookCover) -> Void
    ) {
        self.title = title
        self.makeCoverDrawing = makeCoverDrawing
        self.onSave = onSave
        self.originalStyle = cover.style
        _cover = State(initialValue: cover)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    NotebookCoverView(title: title, cover: cover)
                        .frame(maxHeight: 260)

                    Picker("Estilo", selection: $cover.style) {
                        ForEach(editing.coverStyles(current: originalStyle), id: \.self) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)

                    if cover.style == .drawn {
                        if editing.canDraw {
                            drawingButtons
                        } else {
                            Text("El dibujo de la portada se hace en el iPad.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    LazyVGrid(columns: swatchColumns, spacing: 16) {
                        ForEach(CoverColor.allCases, id: \.self) { color in
                            swatch(color)
                        }
                    }
                }
                .padding(24)
            }
            .fullScreenCover(item: $drawingModule) { module in
                CoverDrawingScreen(viewModel: module.viewModel, canvas: module.canvas, title: title) { drawing in
                    cover.drawing = drawing
                }
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

    private var drawingButtons: some View {
        HStack(spacing: 16) {
            Button {
                drawingModule = makeCoverDrawing(cover.drawing, cover.color)
            } label: {
                Label(
                    cover.drawing == nil ? "Dibujar portada" : "Editar dibujo",
                    systemImage: "pencil.tip.crop.circle"
                )
            }
            .buttonStyle(.borderedProminent)

            if cover.drawing != nil {
                Button("Quitar dibujo", role: .destructive) { cover.drawing = nil }
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
