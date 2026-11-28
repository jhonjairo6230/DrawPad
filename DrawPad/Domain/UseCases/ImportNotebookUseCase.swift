import Foundation

/// Importa un cuaderno exportado con ``ExportNotebookUseCase``.
///
/// Regla: **si el cuaderno ya está en este dispositivo** (mismo
/// identificador), se reemplaza por la versión del archivo: así exportar de
/// nuevo desde el iPad e importar en el iPhone actualiza la copia en lugar de
/// duplicarla. Si no está, se añade tal cual.
struct ImportNotebookUseCase {
    private let notebooks: NotebookRepository
    private let drawings: DrawingRepository
    private let elements: PageElementRepository
    private let coder: NotebookArchiveCoder
    private let reader: ImportedFileReader

    init(
        notebooks: NotebookRepository,
        drawings: DrawingRepository,
        elements: PageElementRepository,
        coder: NotebookArchiveCoder,
        reader: ImportedFileReader
    ) {
        self.notebooks = notebooks
        self.drawings = drawings
        self.elements = elements
        self.coder = coder
        self.reader = reader
    }

    /// - Throws: ``DrawingError/importFailed`` si el archivo no se puede leer
    ///   o no es un cuaderno válido, ``DrawingError/unsupportedArchiveVersion``,
    ///   o los errores del almacenamiento.
    func execute(fileURL: URL) throws -> NotebookImportResult {
        let bundle = try coder.decode(try reader.read(fileURL))
        guard bundle.isConsistent else { throw DrawingError.importFailed }

        let alreadyHere = try notebooks.findNotebook(id: bundle.notebook.id) != nil
        if alreadyHere {
            // Borra también sus hojas y elementos: los del archivo los sustituyen.
            try notebooks.deleteNotebook(id: bundle.notebook.id)
        }
        try notebooks.save(bundle.notebook)
        for page in bundle.pages {
            try drawings.save(page)
        }
        for element in bundle.elements {
            try elements.save(element)
        }
        return NotebookImportResult(notebook: bundle.notebook, replacedExisting: alreadyHere)
    }
}
