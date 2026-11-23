import SwiftUI

/// El lienzo de una hoja a pantalla completa y sus acciones en la barra.
///
/// Se muestra dentro de ``NotebookScreen``, que pone el título y los
/// controles para cambiar de hoja.
///
/// La vista no toma decisiones: traduce toques en llamadas al
/// ``CanvasViewModel`` y pinta su estado. La barra muestra lo que permite el
/// dispositivo (``EditingCapabilities``): en el iPhone, diagramas y
/// "Compartir"; sin trazos ni papel.
struct CanvasScreen: View {
    @Bindable var viewModel: CanvasViewModel
    let canvas: PencilKitCanvas
    let makeMermaidEditor: (String, CanvasTheme) -> MermaidEditorModule

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.editing) private var editing
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
            .sheet(item: $viewModel.mermaidEditor) { request in
                MermaidEditorHost(
                    request: request,
                    theme: viewModel.theme,
                    makeEditor: makeMermaidEditor
                ) { source, snapshot in
                    viewModel.commitMermaid(source: source, snapshot: snapshot, for: request)
                }
            }
            .sheet(item: $viewModel.textEditor) { request in
                TextElementEditorSheet(request: request) { text in
                    viewModel.commitText(text, for: request)
                }
            }
            .overlay(alignment: .top) {
                if viewModel.isArrangingElements {
                    arrangingBar
                }
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
    private var canvasView: some View {
        PencilCanvasView(canvas: canvas)
            .ignoresSafeArea(edges: .bottom)
            .toolbar { toolbarContent }
    }

    /// Barra del modo de mover: qué hacer con lo seleccionado y cómo volver a
    /// dibujar.
    ///
    /// En una línea si cabe; si no (iPhone), el aviso arriba y los botones
    /// debajo.
    private var arrangingBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 20) {
                arrangingHintText
                arrangingButtons
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())

            VStack(spacing: 8) {
                arrangingHintText
                HStack(spacing: 16) { arrangingButtons }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(.top, 12)
        .padding(.horizontal, 8)
    }

    private var arrangingHintText: some View {
        Text(arrangingHint)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var arrangingButtons: some View {
        if viewModel.isConnecting {
            Button("Cancelar") { viewModel.cancelConnecting() }
                .accessibilityIdentifier("Cancelar conexión")
        } else {
            selectionActions
            Button("Listo") { viewModel.setArrangingElements(false) }
                .fontWeight(.semibold)
        }
    }

    private var arrangingHint: String {
        if viewModel.isConnecting { return "Toca el elemento de destino" }
        guard let element = viewModel.selectedElement else { return "Toca un elemento" }
        return element.isConnector ? "Conexión seleccionada" : "Arrastra para mover"
    }

    /// Lo que se puede hacer con el elemento seleccionado.
    @ViewBuilder
    private var selectionActions: some View {
        if let element = viewModel.selectedElement {
            // Los cuadros de texto son del lápiz y el teclado del iPad; el
            // texto de una figura es parte del diagrama.
            if element.isShape || (element.isText && editing.canDraw) {
                Button("Editar texto") { viewModel.beginEditingSelectedText() }
            }
            if element.isMermaid {
                Button("Editar diagrama") { viewModel.beginEditingSelectedMermaid() }
            }
            if element.isShape {
                Button("Girar") { viewModel.rotateSelectedShape() }
            }
            if !element.isConnector {
                Menu("Conectar") {
                    Button { viewModel.beginConnecting(.arrow) } label: {
                        Label("Con flecha", systemImage: "arrow.right")
                    }
                    Button { viewModel.beginConnecting(.line) } label: {
                        Label("Con línea", systemImage: "line.diagonal")
                    }
                }
            }
            Button("Eliminar", role: .destructive) { viewModel.deleteSelectedElement() }
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
        ToolbarItemGroup(placement: .topBarTrailing) {
            // Deshacer y rehacer son de los trazos (PencilKit).
            if editing.canDraw {
                Button { viewModel.undo() } label: {
                    Label("Deshacer", systemImage: "arrow.uturn.backward")
                }
                Button { viewModel.redo() } label: {
                    Label("Rehacer", systemImage: "arrow.uturn.forward")
                }
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if editing.canEditDrawingPages {
                insertMenu
            }
            if editing.canDraw {
                backgroundMenu
                moreMenu
            }
            shareMenu
        }
    }

    /// Insertar elementos y entrar en el modo de mover y conectar.
    private var insertMenu: some View {
        Menu {
            if editing.canDraw {
                Button { viewModel.beginNewText() } label: {
                    Label("Cuadro de texto", systemImage: "character.textbox")
                }
            }
            if editing.canEditDiagrams {
                Button { viewModel.beginNewMermaid() } label: {
                    Label("Diagrama Mermaid", systemImage: "point.3.connected.trianglepath.dotted")
                }
            }
            if editing.canDraw {
                Button { viewModel.paste() } label: {
                    Label("Pegar", systemImage: "doc.on.clipboard")
                }
            }
            if editing.canEditDiagrams {
                Menu {
                    ForEach(ShapeKind.allCases, id: \.self) { kind in
                        Button { viewModel.insertShape(kind) } label: {
                            Label(kind.title, systemImage: kind.symbolName)
                        }
                    }
                } label: {
                    Label("Figura", systemImage: "square.on.circle")
                }
            }
            Divider()
            Button { viewModel.setArrangingElements(true) } label: {
                Label("Mover y conectar", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
            }
            .disabled(viewModel.elements.isEmpty)
        } label: {
            Label("Insertar", systemImage: "plus.rectangle.on.rectangle")
        }
    }

    private var backgroundMenu: some View {
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
    }

    private var moreMenu: some View {
        Menu {
            Toggle(isOn: Binding(
                get: { viewModel.isFingerDrawingEnabled },
                set: { _ in viewModel.toggleFingerDrawing() }
            )) {
                Label("Dibujar con el dedo", systemImage: "hand.draw")
            }
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
    }

    /// Guardar en Fotos y compartir: siempre a mano, también en el iPhone.
    @ViewBuilder
    private var shareMenu: some View {
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
