import Foundation

/// Un cuaderno completo, con todo lo necesario para llevarlo a otro
/// dispositivo: el cuaderno, sus hojas (con los trazos) y los elementos de
/// cada hoja.
///
/// Es lo que se exporta e importa. El dominio no sabe en qué formato se
/// escribe: eso lo decide ``NotebookArchiveCoder``.
struct NotebookBundle: Equatable {
    let notebook: Notebook
    /// Hojas en orden, de la primera a la última.
    let pages: [Drawing]
    /// Elementos de todas las hojas.
    let elements: [PageElement]

    /// Comprueba que el paquete se puede guardar sin romper las reglas: al
    /// menos una hoja, todas del cuaderno, y cada elemento en una de ellas.
    var isConsistent: Bool {
        let pageIDs = Set(pages.map(\.id))
        return !pages.isEmpty
            && pages.allSatisfy { $0.notebookID == notebook.id }
            && pageIDs.count == pages.count
            && elements.allSatisfy { pageIDs.contains($0.pageID) }
    }
}

/// Qué pasó al importar.
struct NotebookImportResult: Equatable {
    let notebook: Notebook
    /// `true` si ya existía y se reemplazó por la versión del archivo.
    let replacedExisting: Bool
}
