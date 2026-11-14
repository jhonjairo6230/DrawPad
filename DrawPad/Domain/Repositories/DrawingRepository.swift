import Foundation

/// Puerto de persistencia del dibujo actual.
///
/// El dominio define **qué** necesita (cargar y guardar); la capa Data decide
/// **cómo** (archivo, base de datos, iCloud…). Esto es la *inversión de
/// dependencias* de Clean Architecture.
protocol DrawingRepository {
    /// Devuelve el último dibujo guardado o `nil` si nunca se guardó nada.
    /// - Throws: ``DrawingError/storageFailed``.
    func load() throws -> Drawing?

    /// Guarda el dibujo, reemplazando el anterior.
    /// - Throws: ``DrawingError/storageFailed``.
    func save(_ drawing: Drawing) throws
}
