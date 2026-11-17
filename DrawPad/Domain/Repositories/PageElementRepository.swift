import Foundation

/// Puerto de persistencia de los elementos de una hoja (textos e imágenes).
///
/// Todos los métodos lanzan ``DrawingError/storageFailed`` si falla el
/// almacenamiento. Al eliminar una hoja o un cuaderno, sus elementos se
/// eliminan con ellos (lo garantizan ``DrawingRepository`` y
/// ``NotebookRepository``).
protocol PageElementRepository {
    /// Los elementos de una hoja, del más antiguo (al fondo) al más nuevo.
    func listElements(pageID: UUID) throws -> [PageElement]

    /// El elemento, o `nil` si no existe.
    func findElement(id: UUID) throws -> PageElement?

    /// Crea el elemento o reemplaza el que tenga el mismo `id`.
    func save(_ element: PageElement) throws

    /// Elimina el elemento. No hace nada si no existe.
    func deleteElement(id: UUID) throws
}
