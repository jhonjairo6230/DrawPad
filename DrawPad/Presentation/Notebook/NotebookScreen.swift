import SwiftUI
import UniformTypeIdentifiers

/// Un cuaderno abierto: muestra la hoja actual y, en la barra, los controles
/// para pasar de hoja, añadir una nueva (botón +) o eliminar la que se ve
/// (menú del título).
///
/// La hoja la pinta ``CanvasScreen`` (dibujo) o ``MarkdownPageScreen``
/// (Markdown); esta vista solo decide **qué hoja**.
struct NotebookScreen: View {
    @Bindable var viewModel: NotebookViewModel

    @State private var isConfirmingDelete = false
    @State private var isImportingMarkdown = false
    @Environment(\.editing) private var editing

    var body: some View {
        page
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { pageControls }
            }
            .onAppear { viewModel.onAppear() }
            .fileImporter(isPresented: $isImportingMarkdown, allowedContentTypes: Self.markdownTypes) { result in
                if case .success(let url) = result {
                    viewModel.importMarkdown(from: url)
                }
            }
            .confirmationDialog(
                "¿Eliminar esta hoja?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Eliminar hoja", role: .destructive) { viewModel.deleteCurrentPage() }
            } message: {
                Text("Se borrará para siempre lo que tiene.")
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

    @ViewBuilder
    private var page: some View {
        // La sesión es un `CanvasModule` en la app; en las pruebas del
        // ViewModel es un doble sin vista.
        if let module = viewModel.session as? CanvasModule {
            CanvasScreen(
                viewModel: module.viewModel,
                canvas: module.canvas,
                makeMermaidEditor: module.makeMermaidEditor
            )
                // Una identidad por hoja: al cambiar, SwiftUI desmonta el
                // lienzo anterior y monta el nuevo.
                .id(module.id)
        } else if let module = viewModel.session as? MarkdownPageModule {
            MarkdownPageScreen(viewModel: module.viewModel, renderer: module.renderer)
                .id(module.id)
        } else {
            Color(.systemBackground)
        }
    }

    /// Archivos que se pueden importar como hoja Markdown.
    private static let markdownTypes: [UTType] = [
        UTType("net.daringfireball.markdown"),
        UTType(filenameExtension: "md"),
        .plainText,
    ].compactMap { $0 }

    /// ‹  Cuaderno 1 · Hoja 2 de 5 ⌄  ›  +
    ///
    /// "Nueva hoja" es un botón a la vista y no una opción del menú: con una
    /// sola hoja las flechas están desactivadas, y sin el + no se veía cómo
    /// añadir la segunda.
    private var pageControls: some View {
        HStack(spacing: 12) {
            Button { viewModel.goToPreviousPage() } label: {
                Label("Hoja anterior", systemImage: "chevron.left")
            }
            .disabled(!viewModel.canGoToPreviousPage)

            if let kind = viewModel.currentPageKind, editing.canDeletePage(of: kind) {
                Menu {
                    Button(role: .destructive) { isConfirmingDelete = true } label: {
                        Label("Eliminar esta hoja", systemImage: "trash")
                    }
                    .disabled(!viewModel.canDeletePage)
                } label: {
                    HStack(spacing: 4) {
                        pageTitle
                        // Indica que el título se puede tocar.
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                }
                .accessibilityIdentifier("Hojas")
            } else {
                pageTitle
            }

            Button { viewModel.goToNextPage() } label: {
                Label("Hoja siguiente", systemImage: "chevron.right")
            }
            .disabled(!viewModel.canGoToNextPage)

            if editing.canAddPages {
                Menu {
                    if editing.canAddDrawingPages {
                        Button { viewModel.addPage(.drawing) } label: {
                            Label("Hoja de dibujo", systemImage: "pencil.and.scribble")
                        }
                    }
                    if editing.canWriteMarkdown {
                        Button { viewModel.addPage(.markdown) } label: {
                            Label("Hoja Markdown", systemImage: "doc.richtext")
                        }
                        Divider()
                        Button { isImportingMarkdown = true } label: {
                            Label("Importar Markdown…", systemImage: "square.and.arrow.down")
                        }
                    }
                } label: {
                    Label("Nueva hoja", systemImage: "plus")
                }
            }
        }
        .labelStyle(.iconOnly)
    }

    private var pageTitle: some View {
        Text("\(viewModel.title) · \(viewModel.pageLabel)")
            .font(.headline)
            .lineLimit(1)
    }

    private var isShowingAlert: Binding<Bool> {
        Binding(get: { viewModel.alert != nil }, set: { if !$0 { viewModel.alert = nil } })
    }
}
