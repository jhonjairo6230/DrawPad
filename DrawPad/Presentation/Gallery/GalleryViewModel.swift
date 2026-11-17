import Foundation
import Observation

/// Estado y acciones de la galería de cuadernos (patrón MVVM).
@MainActor
@Observable
final class GalleryViewModel {
    /// Cuadernos a mostrar, del usado más recientemente al más antiguo.
    private(set) var notebooks: [NotebookSummary] = []
    var alert: AlertMessage?

    private let listNotebooks: ListNotebooksUseCase
    private let createNotebook: CreateNotebookUseCase
    private let renameNotebook: RenameNotebookUseCase
    private let deleteNotebook: DeleteNotebookUseCase
    private let changeCover: ChangeCoverUseCase

    init(
        listNotebooks: ListNotebooksUseCase,
        createNotebook: CreateNotebookUseCase,
        renameNotebook: RenameNotebookUseCase,
        deleteNotebook: DeleteNotebookUseCase,
        changeCover: ChangeCoverUseCase
    ) {
        self.listNotebooks = listNotebooks
        self.createNotebook = createNotebook
        self.renameNotebook = renameNotebook
        self.deleteNotebook = deleteNotebook
        self.changeCover = changeCover
    }

    /// Vuelve a leer la lista (al aparecer y al volver de un cuaderno).
    func load() {
        perform { notebooks = try listNotebooks.execute() }
    }

    /// Crea un cuaderno con una hoja en blanco.
    /// - Returns: su identificador, para abrirlo; `nil` si falló.
    func create() -> UUID? {
        var id: UUID?
        perform {
            id = try createNotebook.execute().id
            notebooks = try listNotebooks.execute()
        }
        return id
    }

    func rename(id: UUID, to title: String) {
        perform {
            try renameNotebook.execute(id: id, title: title)
            notebooks = try listNotebooks.execute()
        }
    }

    func changeCover(id: UUID, to cover: NotebookCover) {
        perform {
            try changeCover.execute(id: id, cover: cover)
            notebooks = try listNotebooks.execute()
        }
    }

    func delete(id: UUID) {
        perform {
            try deleteNotebook.execute(id: id)
            notebooks = try listNotebooks.execute()
        }
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
