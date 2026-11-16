import SwiftUI

/// Un cuaderno abierto: muestra la hoja actual y, en la barra, los controles
/// para pasar de hoja, añadir una nueva o eliminar la que se ve.
///
/// El lienzo lo pinta ``CanvasScreen``; esta vista solo decide **qué hoja**.
struct NotebookScreen: View {
    @Bindable var viewModel: NotebookViewModel

    @State private var isConfirmingDelete = false

    var body: some View {
        page
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { pageControls }
            }
            .onAppear { viewModel.onAppear() }
            .confirmationDialog(
                "¿Eliminar esta hoja?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Eliminar hoja", role: .destructive) { viewModel.deleteCurrentPage() }
            } message: {
                Text("Se borrará para siempre lo dibujado en ella.")
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
            CanvasScreen(viewModel: module.viewModel, canvas: module.canvas)
                // Una identidad por hoja: al cambiar, SwiftUI desmonta el
                // lienzo anterior y monta el nuevo.
                .id(module.id)
        } else {
            Color(.systemBackground)
        }
    }

    /// ‹  Cuaderno 1 · Hoja 2 de 5  ›
    private var pageControls: some View {
        HStack(spacing: 12) {
            Button { viewModel.goToPreviousPage() } label: {
                Label("Hoja anterior", systemImage: "chevron.left")
            }
            .disabled(!viewModel.canGoToPreviousPage)

            Menu {
                Button { viewModel.addPage() } label: {
                    Label("Nueva hoja", systemImage: "plus")
                }
                Button(role: .destructive) { isConfirmingDelete = true } label: {
                    Label("Eliminar esta hoja", systemImage: "trash")
                }
                .disabled(!viewModel.canDeletePage)
            } label: {
                Text("\(viewModel.title) · \(viewModel.pageLabel)")
                    .font(.headline)
                    .lineLimit(1)
            }
            .accessibilityIdentifier("Hojas")

            Button { viewModel.goToNextPage() } label: {
                Label("Hoja siguiente", systemImage: "chevron.right")
            }
            .disabled(!viewModel.canGoToNextPage)
        }
        .labelStyle(.iconOnly)
    }

    private var isShowingAlert: Binding<Bool> {
        Binding(get: { viewModel.alert != nil }, set: { if !$0 { viewModel.alert = nil } })
    }
}
