import SwiftUI

/// Una hoja Markdown: el documento formateado o, en modo "Editar", su texto.
///
/// Se puede editar en el iPad y en el iPhone (ver docs/adr/0021).
struct MarkdownPageScreen: View {
    @Bindable var viewModel: MarkdownPageViewModel
    let renderer: WebKitMarkdownRenderer

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.editing) private var editing

    var body: some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if editing.canWriteMarkdown {
                        Picker("Modo", selection: $viewModel.mode) {
                            Text("Ver").tag(MarkdownPageViewModel.Mode.read)
                            Text("Editar").tag(MarkdownPageViewModel.Mode.edit)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    Menu {
                        Button { viewModel.export() } label: {
                            Label("Exportar como .md", systemImage: "doc.text")
                        }
                    } label: {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .onAppear { viewModel.onAppear() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { viewModel.flushPendingSave() }
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

    @ViewBuilder
    private var content: some View {
        if editing.canWriteMarkdown && viewModel.mode == .edit {
            TextEditor(text: Binding(
                get: { viewModel.text },
                set: { viewModel.updateText($0) }
            ))
            .font(.system(.body, design: .monospaced))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.horizontal, 16)
            .accessibilityLabel("Texto Markdown")
        } else {
            MarkdownWebView(renderer: renderer, markdown: viewModel.text)
                .ignoresSafeArea(edges: .bottom)
                .accessibilityIdentifier("Documento Markdown")
        }
    }

    private var isShowingAlert: Binding<Bool> {
        Binding(get: { viewModel.alert != nil }, set: { if !$0 { viewModel.alert = nil } })
    }
}
