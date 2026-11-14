import SwiftUI

/// Pantalla principal: el lienzo a pantalla completa y una barra de acciones.
///
/// La vista no toma decisiones: traduce toques en llamadas al
/// ``CanvasViewModel`` y pinta su estado.
struct CanvasScreen: View {
    @Bindable var viewModel: CanvasViewModel
    let canvas: PencilKitCanvas

    @Environment(\.scenePhase) private var scenePhase
    @State private var isConfirmingClear = false

    var body: some View {
        NavigationStack {
            PencilCanvasView(canvas: canvas)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("DrawPad")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
        .onAppear { viewModel.onAppear() }
        .onChange(of: scenePhase) { _, phase in
            // Al salir de la app (o al cerrarla) no se pierde lo último dibujado.
            if phase != .active { viewModel.flushPendingSave() }
        }
        .confirmationDialog(
            "¿Borrar todo el dibujo?",
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

    /// Adapta `alert: AlertMessage?` al `Bool` que pide `.alert`.
    private var isShowingAlert: Binding<Bool> {
        Binding(
            get: { viewModel.alert != nil },
            set: { if !$0 { viewModel.alert = nil } }
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button { viewModel.undo() } label: {
                Label("Deshacer", systemImage: "arrow.uturn.backward")
            }
            Button { viewModel.redo() } label: {
                Label("Rehacer", systemImage: "arrow.uturn.forward")
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
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

            if viewModel.isExporting {
                ProgressView()
            } else {
                Button { Task { await viewModel.export() } } label: {
                    Label("Guardar en Fotos", systemImage: "square.and.arrow.down")
                }
            }
        }
    }
}
