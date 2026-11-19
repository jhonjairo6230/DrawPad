import Foundation

/// Lo que el editor de diagramas necesita del motor de Mermaid.
///
/// Es un puerto de la capa de presentación, como ``DrawingCanvas``: el
/// ViewModel habla con este protocolo y no con WebKit, y en las pruebas se
/// sustituye por uno falso.
@MainActor
protocol MermaidPreview: AnyObject {
    /// Dibuja el texto en la vista previa.
    func render(source: String, theme: CanvasTheme) async -> MermaidPreviewOutcome

    /// La imagen del último diagrama dibujado correctamente.
    /// - Throws: ``DrawingError/invalidDiagram(_:)`` si no hay diagrama o no se
    ///   pudo convertir en imagen.
    func snapshot() async throws -> MermaidSnapshot
}

/// Resultado de dibujar un texto de Mermaid.
enum MermaidPreviewOutcome: Equatable {
    /// Dibujado; lleva el tamaño del diagrama en puntos.
    case rendered(CGSize)
    /// Mermaid no lo entendió; lleva su mensaje.
    case failed(String)
}

/// Un diagrama convertido en imagen.
struct MermaidSnapshot: Equatable {
    /// PNG.
    let image: Data
    /// Tamaño en puntos.
    let size: CGSize
}
