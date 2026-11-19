import SwiftUI

/// Pantalla completa para dibujar la portada con el Pencil.
///
/// El lienzo tiene **siempre el mismo tamaño** (``canvasSize``), en la
/// proporción de la tapa (3:4): así el dibujo cae en el mismo sitio aunque se
/// edite con el iPad en otra orientación, y la imagen encaja en la tapa.
struct CoverDrawingScreen: View {
    static let canvasSize = CGSize(width: 420, height: 560)

    @Bindable var viewModel: CoverDrawingViewModel
    let canvas: PencilKitCanvas
    let title: String
    /// `nil` si el lienzo quedó vacío.
    let onFinish: (CoverDrawing?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingClear = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                PencilCanvasView(canvas: canvas)
                    .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(alignment: .bottom) { titleBand }
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

                Text("El título se muestra siempre en la franja de abajo.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dibujar portada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { viewModel.onAppear() }
            .confirmationDialog(
                "¿Borrar todo el dibujo de la portada?",
                isPresented: $isConfirmingClear,
                titleVisibility: .visible
            ) {
                Button("Borrar todo", role: .destructive) { viewModel.clear() }
            }
            .alert(
                viewModel.alert?.title ?? "",
                isPresented: isShowingAlert,
                presenting: viewModel.alert
            ) { _ in
                Button("Aceptar", role: .cancel) {}
            } message: { alert in
                Text(alert.message)
            }
        }
    }

    /// La misma franja que se verá en la galería, para dibujar sin taparla.
    private var titleBand: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.35))
            .allowsHitTesting(false)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancelar") { dismiss() }
                // Debajo sigue abierto el editor de portada, con su propio
                // "Cancelar": un identificador distinto evita confundirlos.
                .accessibilityIdentifier("Cancelar dibujo")
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Usar dibujo") {
                onFinish(viewModel.finish())
                dismiss()
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { viewModel.undo() } label: {
                Label("Deshacer", systemImage: "arrow.uturn.backward")
            }
            Button { viewModel.redo() } label: {
                Label("Rehacer", systemImage: "arrow.uturn.forward")
            }
            Toggle(isOn: Binding(
                get: { viewModel.isFingerDrawingEnabled },
                set: { _ in viewModel.toggleFingerDrawing() }
            )) {
                Label("Dibujar con el dedo", systemImage: "hand.draw")
            }
            .toggleStyle(.button)
            Button(role: .destructive) { isConfirmingClear = true } label: {
                Label("Borrar todo", systemImage: "trash")
            }
        }
    }

    private var isShowingAlert: Binding<Bool> {
        Binding(get: { viewModel.alert != nil }, set: { if !$0 { viewModel.alert = nil } })
    }
}
