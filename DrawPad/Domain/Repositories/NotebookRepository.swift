import Foundation

/// Puerto de persistencia de los cuadernos.
///
/// Todos los métodos lanzan ``DrawingError/storageFailed`` si falla el
/// almacenamiento.
protocol NotebookRepository {
    /// Resúmenes de todos los cuadernos, del usado más recientemente al más antiguo.
    func listNotebooks() throws -> [NotebookSummary]

    /// El cuaderno, o `nil` si no existe.
    func findNotebook(id: UUID) throws -> Notebook?

    /// Crea el cuaderno o reemplaza el que tenga el mismo `id`.
    func save(_ notebook: Notebook) throws

    /// Elimina el cuaderno **y todas sus hojas**. No hace nada si no existe.
    func deleteNotebook(id: UUID) throws
}
