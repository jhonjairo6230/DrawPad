import Foundation
import Observation

/// Estado y acciones de un cuaderno abierto (patrón MVVM): qué hoja se ve y
/// las operaciones de pasar, añadir y eliminar hojas.
///
/// No dibuja: cada hoja abierta es una ``PageSession`` que crea la fábrica
/// `makeSession`. Al cambiar de hoja se guarda lo pendiente de la anterior.
@MainActor
@Observable
final class NotebookViewModel {
    private(set) var title = ""
    /// Hojas del cuaderno, de la primera a la última.
    private(set) var pages: [DrawingSummary] = []
    private(set) var currentIndex = 0
    /// La hoja que se está viendo; `nil` hasta que carga el cuaderno.
    private(set) var session: PageSession?
    var alert: AlertMessage?

    private let notebookID: UUID
    private let loadNotebook: LoadNotebookUseCase
    private let listPages: ListPagesUseCase
    private let addPageUseCase: AddPageUseCase
    private let deletePage: DeletePageUseCase
    private let makeSession: (_ pageID: UUID, _ shareName: String) -> PageSession

    @ObservationIgnored private var hasLoaded = false

    /// - Parameter makeSession: monta la pantalla de una hoja. Recibe su
    ///   identificador y el nombre para el archivo al compartir.
    init(
        notebookID: UUID,
        loadNotebook: LoadNotebookUseCase,
        listPages: ListPagesUseCase,
        addPage: AddPageUseCase,
        deletePage: DeletePageUseCase,
        makeSession: @escaping (_ pageID: UUID, _ shareName: String) -> PageSession
    ) {
        self.notebookID = notebookID
        self.loadNotebook = loadNotebook
        self.listPages = listPages
        self.addPageUseCase = addPage
        self.deletePage = deletePage
        self.makeSession = makeSession
    }

    // MARK: - Estado derivado

    /// "Hoja 2 de 5".
    var pageLabel: String {
        pages.isEmpty ? "" : "Hoja \(currentIndex + 1) de \(pages.count)"
    }

    var canGoToPreviousPage: Bool { currentIndex > 0 }

    var canGoToNextPage: Bool { currentIndex < pages.count - 1 }

    /// Un cuaderno necesita al menos una hoja.
    var canDeletePage: Bool { pages.count > 1 }

    // MARK: - Ciclo de vida

    /// Carga el cuaderno y abre su primera hoja. Solo actúa la primera vez.
    func onAppear() {
        guard !hasLoaded else { return }
        hasLoaded = true
        perform {
            title = try loadNotebook.execute(id: notebookID).title
            pages = try listPages.execute(notebookID: notebookID)
            open(pageAt: 0)
        }
    }

    /// Guarda ya lo pendiente de la hoja abierta (se sale del cuaderno).
    func flushPendingSave() {
        session?.flushPendingSave()
    }

    // MARK: - Acciones del usuario

    func goToPreviousPage() {
        guard canGoToPreviousPage else { return }
        open(pageAt: currentIndex - 1)
    }

    func goToNextPage() {
        guard canGoToNextPage else { return }
        open(pageAt: currentIndex + 1)
    }

    /// Añade una hoja al final y la abre.
    func addPage() {
        perform {
            let page = try addPageUseCase.execute(notebookID: notebookID)
            pages = try listPages.execute(notebookID: notebookID)
            open(pageAt: pages.firstIndex { $0.id == page.id } ?? pages.count - 1)
        }
    }

    /// Elimina la hoja que se está viendo y abre la que queda en su lugar.
    func deleteCurrentPage() {
        guard pages.indices.contains(currentIndex) else { return }
        let pageID = pages[currentIndex].id
        perform {
            try deletePage.execute(id: pageID)
            // La hoja ya no existe: su autoguardado pendiente fallaría.
            session?.discardPendingSave()
            session = nil
            pages = try listPages.execute(notebookID: notebookID)
            open(pageAt: min(currentIndex, pages.count - 1))
        }
    }

    // MARK: - Privado

    private func open(pageAt index: Int) {
        guard pages.indices.contains(index) else { return }
        session?.flushPendingSave()
        currentIndex = index
        session = makeSession(pages[index].id, "\(title) - Hoja \(index + 1)")
    }

    /// Ejecuta una operación y convierte cualquier error en una alerta.
    private func perform(_ operation: () throws -> Void) {
        do {
            try operation()
        } catch {
            alert = AlertMessage(error: error)
        }
    }
}

extension NotebookViewModel: Hashable {
    // Por identidad: la galería guarda "el cuaderno abierto" como destino de
    // navegación, y SwiftUI necesita poder comparar ese valor.
    nonisolated static func == (lhs: NotebookViewModel, rhs: NotebookViewModel) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
