import SwiftUI

/// Pantalla inicial: la cuadrícula de dibujos.
///
/// También es la dueña de la navegación: guarda el dibujo abierto
/// (`openCanvas`) y SwiftUI muestra ``CanvasScreen`` mientras no sea `nil`.
struct GalleryScreen: View {
    @Bindable var viewModel: GalleryViewModel
    /// Fábrica que monta la pantalla de un dibujo (la da ``AppContainer``).
    let makeCanvas: (UUID) -> CanvasModule

    @State private var openCanvas: CanvasModule?
    @State private var drawingToRename: DrawingSummary?
    @State private var newTitle = ""
    @State private var drawingToDelete: DrawingSummary?

    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 24)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Dibujos")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { createAndOpen() } label: {
                            Label("Nuevo dibujo", systemImage: "plus")
                        }
                    }
                }
                .navigationDestination(item: $openCanvas) { module in
                    CanvasScreen(viewModel: module.viewModel, canvas: module.canvas)
                }
        }
        .onAppear { viewModel.load() }
        .onChange(of: openCanvas) { closed, opened in
            // Al volver de un dibujo: guardar lo pendiente y refrescar la
            // lista, en ese orden, para que la miniatura salga actualizada.
            guard opened == nil else { return }
            closed?.viewModel.flushPendingSave()
            viewModel.load()
        }
        .alert("Renombrar dibujo", isPresented: isRenaming) {
            TextField("Título", text: $newTitle)
            Button("Guardar") {
                if let drawing = drawingToRename {
                    viewModel.rename(id: drawing.id, to: newTitle)
                }
            }
            Button("Cancelar", role: .cancel) {}
        }
        .confirmationDialog(
            "¿Eliminar este dibujo?",
            isPresented: isDeleting,
            titleVisibility: .visible,
            presenting: drawingToDelete
        ) { drawing in
            Button("Eliminar", role: .destructive) { viewModel.delete(id: drawing.id) }
        } message: { drawing in
            Text("\"\(drawing.title)\" se borrará para siempre.")
        }
        .background {
            // Segunda alerta en otra vista: dos `.alert` en la misma no conviven bien.
            Color.clear.alert(
                viewModel.alert?.title ?? "",
                isPresented: isShowingError,
                presenting: viewModel.alert
            ) { _ in
                Button("Aceptar", role: .cancel) {}
            } message: { alert in
                Text(alert.message)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.drawings.isEmpty {
            ContentUnavailableView(
                "Aún no hay dibujos",
                systemImage: "scribble.variable",
                description: Text("Toca + para crear el primero.")
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(viewModel.drawings) { drawing in
                        Button { open(drawing.id) } label: {
                            DrawingCard(drawing: drawing)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(drawing.title)
                        .contextMenu {
                            Button {
                                newTitle = drawing.title
                                drawingToRename = drawing
                            } label: {
                                Label("Renombrar", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                drawingToDelete = drawing
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    // MARK: - Acciones

    private func open(_ id: UUID) {
        openCanvas = makeCanvas(id)
    }

    private func createAndOpen() {
        guard let id = viewModel.create() else { return }
        open(id)
    }

    // MARK: - Enlaces para alertas y diálogos

    private var isRenaming: Binding<Bool> {
        Binding(get: { drawingToRename != nil }, set: { if !$0 { drawingToRename = nil } })
    }

    private var isDeleting: Binding<Bool> {
        Binding(get: { drawingToDelete != nil }, set: { if !$0 { drawingToDelete = nil } })
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { viewModel.alert != nil }, set: { if !$0 { viewModel.alert = nil } })
    }
}
