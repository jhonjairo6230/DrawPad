import UniformTypeIdentifiers

extension UTType {
    /// Tipo de archivo de un cuaderno exportado (`.drawpad`). Se declara en
    /// `project.yml` (`UTExportedTypeDeclarations`) con este mismo
    /// identificador, para que la app Archivos sepa que lo abre DrawPad.
    static let drawPadNotebook = UTType(exportedAs: "com.jhonjairo6230.drawpad.notebook")
}
