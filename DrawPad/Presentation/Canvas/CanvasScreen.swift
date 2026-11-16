import SwiftUI

/// El lienzo de una hoja a pantalla completa y sus acciones en la barra.
///
/// Se muestra dentro de ``NotebookScreen``, que pone el título y los
/// controles para cambiar de hoja.
///
/// La vista no toma decisiones: traduce toques en llamadas al
/// ``CanvasViewModel`` y pinta su estado.
struct CanvasScreen: View {
    @Bindable var viewModel: CanvasViewModel
    let canvas: PencilKitCanvas

    @Environment(\.scenePhase) private var scenePhase
    @State private var isConfirmingClear = false

    var body: some View {
        canvasView
            .onAppear { viewModel.onAppear() }
            .onChange(of: scenePhase) { _, phase in
                // Al salir de la app (o al cerrarla) no se pierde lo último dibujado.
                if phase != .active { viewModel.flushPendingSave() }
            }
            .confirmationDialog(
                "¿Borrar todo lo dibujado en esta hoja?",
                isPresented: $isConfirmingClear,
                titleVisibility: .visible
            ) {
                Button("Borrar todo", role: .destructive) { viewModel.clear() }
            }
            .sheet(item: $viewModel.sharedFile) { file in
                ActivityView(items: [file.url])
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

    private var canvasView: some View {
        PencilCanvasView(canvas: canvas)
            .ignoresSafeArea(edges: .bottom)
            .toolbar { toolbarContent }
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
        ToolbarItemGroup(placement: .topBarTrailing) {
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

            Menu {
                Picker("Fondo", selection: Binding(
                    get: { viewModel.background },
                    set: { viewModel.setBackground($0) }
                )) {
                    ForEach(CanvasBackground.allCases, id: \.self) { background in
                        Label(background.title, systemImage: background.symbolName)
                            .tag(background)
                    }
                }
                Divider()
                Toggle(isOn: Binding(
                    get: { viewModel.theme == .dark },
                    set: { viewModel.setTheme($0 ? .dark : .light) }
                )) {
                    Label("Papel oscuro", systemImage: "moon")
                }
            } label: {
                Label("Fondo", systemImage: "square.grid.3x3")
            }

            Menu {
                Button { viewModel.smoothStrokes() } label: {
                    Label("Suavizar trazos", systemImage: "wand.and.stars")
                }
                Divider()
                Button(role: .destructive) { isConfirmingClear = true } label: {
                    Label("Borrar todo", systemImage: "trash")
                }
            } label: {
                Label("Más", systemImage: "ellipsis.circle")
            }

            if viewModel.isExporting {
                ProgressView()
            } else {
                Menu {
                    Button { Task { await viewModel.export() } } label: {
                        Label("Guardar en Fotos", systemImage: "square.and.arrow.down")
                    }
                    Divider()
                    Button { viewModel.share(as: .png) } label: {
                        Label("Compartir como imagen", systemImage: "photo")
                    }
                    Button { viewModel.share(as: .pdf) } label: {
                        Label("Compartir como PDF", systemImage: "doc.richtext")
                    }
                } label: {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}
