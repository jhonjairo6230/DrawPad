import Foundation

/// Puerto de persistencia de las hojas.
///
/// El dominio define **qué** necesita; la capa Data decide **cómo** (hoy, una
/// base de datos SwiftData). Esto es la *inversión de dependencias* de Clean
/// Architecture.
///
/// Todos los métodos lanzan ``DrawingError/storageFailed`` si falla el
/// almacenamiento.
protocol DrawingRepository {
    /// Las hojas de un cuaderno, en orden: de la primera a la última.
    func listDrawings(notebookID: UUID) throws -> [DrawingSummary]

    /// La hoja completa, o `nil` si no existe.
    func findDrawing(id: UUID) throws -> Drawing?

    /// Crea la hoja o reemplaza la que tenga el mismo `id`.
    func save(_ drawing: Drawing) throws

    /// Elimina la hoja. No hace nada si no existe.
    func deleteDrawing(id: UUID) throws
}
