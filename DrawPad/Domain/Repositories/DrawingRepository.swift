import Foundation

/// Puerto de persistencia de los dibujos.
///
/// El dominio define **qué** necesita; la capa Data decide **cómo** (hoy, una
/// base de datos SwiftData). Esto es la *inversión de dependencias* de Clean
/// Architecture.
///
/// Todos los métodos lanzan ``DrawingError/storageFailed`` si falla el
/// almacenamiento.
protocol DrawingRepository {
    /// Resúmenes de todos los dibujos, del más reciente al más antiguo.
    func list() throws -> [DrawingSummary]

    /// El dibujo completo, o `nil` si no existe.
    func find(id: UUID) throws -> Drawing?

    /// Crea el dibujo o reemplaza el que tenga el mismo `id`.
    func save(_ drawing: Drawing) throws

    /// Elimina el dibujo. No hace nada si no existe.
    func delete(id: UUID) throws
}
