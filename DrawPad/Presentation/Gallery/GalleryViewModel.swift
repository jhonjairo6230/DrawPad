import Foundation
import Observation

/// Estado y acciones de la galería de dibujos (patrón MVVM).
@MainActor
@Observable
final class GalleryViewModel {
    /// Dibujos a mostrar, del más reciente al más antiguo.
    private(set) var drawings: [DrawingSummary] = []
    var alert: AlertMessage?

    private let listDrawings: ListDrawingsUseCase
    private let createDrawing: CreateDrawingUseCase
    private let renameDrawing: RenameDrawingUseCase
    private let deleteDrawing: DeleteDrawingUseCase

    init(
        listDrawings: ListDrawingsUseCase,
        createDrawing: CreateDrawingUseCase,
        renameDrawing: RenameDrawingUseCase,
        deleteDrawing: DeleteDrawingUseCase
    ) {
        self.listDrawings = listDrawings
        self.createDrawing = createDrawing
        self.renameDrawing = renameDrawing
        self.deleteDrawing = deleteDrawing
    }

    /// Vuelve a leer la lista (al aparecer y al volver de un dibujo).
    func load() {
        perform { drawings = try listDrawings.execute() }
    }

    /// Crea un dibujo vacío.
    /// - Returns: su identificador, para abrirlo; `nil` si falló.
    func create() -> UUID? {
        var id: UUID?
        perform {
            id = try createDrawing.execute().id
            drawings = try listDrawings.execute()
        }
        return id
    }

    func rename(id: UUID, to title: String) {
        perform {
            try renameDrawing.execute(id: id, title: title)
            drawings = try listDrawings.execute()
        }
    }

    func delete(id: UUID) {
        perform {
            try deleteDrawing.execute(id: id)
            drawings = try listDrawings.execute()
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
