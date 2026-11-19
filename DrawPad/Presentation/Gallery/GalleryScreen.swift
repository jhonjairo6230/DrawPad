import SwiftUI
import UniformTypeIdentifiers

/// Pantalla inicial: la cuadrícula de cuadernos.
///
/// También es la dueña de la navegación: guarda el cuaderno abierto
/// (`openNotebook`) y SwiftUI muestra ``NotebookScreen`` mientras no sea `nil`.
struct GalleryScreen: View {
    @Bindable var viewModel: GalleryViewModel
    /// Fábrica que monta un cuaderno abierto (la da ``AppContainer``).
    let makeNotebook: (UUID) -> NotebookViewModel
    /// Fábrica de la pantalla para dibujar una portada (la da ``AppContainer``).
    let makeCoverDrawing: (CoverDrawing?, CoverColor) -> CoverDrawingModule

    @State private var openNotebook: NotebookViewModel?
    @State private var notebookToRename: NotebookSummary?
    @State private var newTitle = ""
    @State private var notebookToDelete: NotebookSummary?
    @State private var notebookToRestyle: NotebookSummary?
    @State private var isImporting = false
    @Environment(\.canEdit) private var canEdit

    private let columns = [GridItem(.adaptive(minimum: 170), spacing: 28)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Cuadernos")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button { isImporting = true } label: {
                            Label("Importar", systemImage: "square.and.arrow.down.on.square")
                        }
                        if canEdit {
                            Button { createAndOpen() } label: {
                                Label("Nuevo cuaderno", systemImage: "plus")
                            }
                        }
                    }
                }
                .navigationDestination(item: $openNotebook) { notebook in
                    NotebookScreen(viewModel: notebook)
                }
        }
        .onAppear { viewModel.load() }
        // Elegir un archivo .drawpad en Archivos / iCloud Drive.
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.drawPadNotebook]) { result in
            if case .success(let url) = result {
                viewModel.importNotebook(from: url)
            }
        }
        // Tocar un archivo .drawpad en la app Archivos abre DrawPad con él.
        .onOpenURL { url in
            openNotebook = nil
            viewModel.importNotebook(from: url)
        }
        .sheet(item: $viewModel.sharedFile) { file in
            ActivityView(items: [file.url])
        }
        .onChange(of: openNotebook) { closed, opened in
            // Al volver de un cuaderno: guardar lo pendiente y refrescar la
            // lista, en ese orden, para que la portada salga actualizada.
            guard opened == nil else { return }
            closed?.flushPendingSave()
            viewModel.load()
        }
        .sheet(item: $notebookToRestyle) { notebook in
            CoverEditorSheet(
                title: notebook.title,
                cover: notebook.cover,
                makeCoverDrawing: makeCoverDrawing
            ) { cover in
                viewModel.changeCover(id: notebook.id, to: cover)
            }
        }
        .alert("Renombrar cuaderno", isPresented: isRenaming) {
            TextField("Título", text: $newTitle)
            Button("Guardar") {
                if let notebook = notebookToRename {
                    viewModel.rename(id: notebook.id, to: newTitle)
                }
            }
            Button("Cancelar", role: .cancel) {}
        }
        .confirmationDialog(
            "¿Eliminar este cuaderno?",
            isPresented: isDeleting,
            titleVisibility: .visible,
            presenting: notebookToDelete
        ) { notebook in
            Button("Eliminar", role: .destructive) { viewModel.delete(id: notebook.id) }
        } message: { notebook in
            Text("\"\(notebook.title)\" y todas sus hojas se borrarán para siempre.")
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
        if viewModel.notebooks.isEmpty {
            ContentUnavailableView(
                "Aún no hay cuadernos",
                systemImage: "book.closed",
                description: Text(canEdit
                    ? "Toca + para crear el primero."
                    : "Exporta un cuaderno en el iPad y ábrelo aquí con Importar.")
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(viewModel.notebooks) { notebook in
                        Button { open(notebook.id) } label: {
                            NotebookCard(notebook: notebook)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(notebook.title)
                        .contextMenu {
                            if canEdit {
                                Button {
                                    newTitle = notebook.title
                                    notebookToRename = notebook
                                } label: {
                                    Label("Renombrar", systemImage: "pencil")
                                }
                                Button {
                                    notebookToRestyle = notebook
                                } label: {
                                    Label("Cambiar portada", systemImage: "paintpalette")
                                }
                            }
                            Button {
                                viewModel.export(id: notebook.id)
                            } label: {
                                Label("Exportar", systemImage: "square.and.arrow.up")
                            }
                            Button(role: .destructive) {
                                notebookToDelete = notebook
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
        openNotebook = makeNotebook(id)
    }

    private func createAndOpen() {
        guard let id = viewModel.create() else { return }
        open(id)
    }

    // MARK: - Enlaces para alertas y diálogos

    private var isRenaming: Binding<Bool> {
        Binding(get: { notebookToRename != nil }, set: { if !$0 { notebookToRename = nil } })
    }

    private var isDeleting: Binding<Bool> {
        Binding(get: { notebookToDelete != nil }, set: { if !$0 { notebookToDelete = nil } })
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { viewModel.alert != nil }, set: { if !$0 { viewModel.alert = nil } })
    }
}
