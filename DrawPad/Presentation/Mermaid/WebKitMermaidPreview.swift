import UIKit
import WebKit

/// Implementación de ``MermaidPreview`` con WebKit y la librería Mermaid
/// incluida en la app (`Resources/Mermaid/mermaid.min.js`).
///
/// - **Sin conexión:** el JavaScript se lee del propio paquete de la app y la
///   página se carga desde texto, sin pedir nada a internet. El texto del
///   usuario no sale del iPad.
/// - **Vista previa visible:** la misma `webView` se muestra en el editor.
///   Capturar una vista web que no está en pantalla no es fiable, así que la
///   imagen se saca de la que el usuario está viendo.
/// - **Imagen:** se pide a WebKit un PDF del recuadro del diagrama (incluye lo
///   que no cabe en pantalla) y se convierte en PNG. Si eso falla, se usa una
///   captura de la parte visible.
///
/// Es el único lugar de la app que conoce WebKit (ver docs/adr/0019).
@MainActor
final class WebKitMermaidPreview: NSObject, MermaidPreview {
    /// Versión de Mermaid incluida en la app.
    static let mermaidVersion = "11.17.2"
    /// Resolución de la imagen resultante (píxeles por punto).
    private static let imageScale: CGFloat = 2

    let webView: WKWebView
    /// Recuadro del último diagrama dibujado, en coordenadas de la página.
    private var lastRect = CGRect.zero
    private var isLoaded = false
    private var loadWaiters: [CheckedContinuation<Void, Never>] = []

    override init() {
        let configuration = WKWebViewConfiguration()
        // Nada se guarda en disco: ni caché ni datos de sitios.
        configuration.websiteDataStore = .nonPersistent()
        if let script = Self.mermaidScript {
            configuration.userContentController.addUserScript(
                WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            )
        }
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.loadHTMLString(Self.page, baseURL: nil)
    }

    // MARK: - MermaidPreview

    func render(source: String, theme: CanvasTheme) async -> MermaidPreviewOutcome {
        guard Self.mermaidScript != nil else {
            return .failed("no se encontró Mermaid dentro de la app")
        }
        await waitUntilLoaded()
        do {
            let result = try await webView.callAsyncJavaScript(
                Self.renderFunction,
                arguments: ["source": source, "theme": theme == .dark ? "dark" : "default"],
                in: nil,
                contentWorld: .page
            )
            guard let values = result as? [String: Any] else {
                return .failed("Mermaid no devolvió ningún diagrama")
            }
            if let message = values["error"] as? String {
                lastRect = .zero
                return .failed(message)
            }
            let rect = CGRect(
                x: Self.number(values["x"]),
                y: Self.number(values["y"]),
                width: Self.number(values["width"]),
                height: Self.number(values["height"])
            )
            guard rect.width > 0, rect.height > 0 else {
                lastRect = .zero
                return .failed("el diagrama quedó vacío")
            }
            lastRect = rect
            return .rendered(rect.size)
        } catch {
            lastRect = .zero
            return .failed(error.localizedDescription)
        }
    }

    func snapshot() async throws -> MermaidSnapshot {
        guard lastRect.width > 0, lastRect.height > 0 else {
            throw DrawingError.invalidDiagram("no hay ningún diagrama dibujado")
        }
        if let image = try? await pdfImage() {
            return image
        }
        return try await visibleImage()
    }

    // MARK: - Imagen

    /// PDF del recuadro del diagrama, convertido en PNG.
    private func pdfImage() async throws -> MermaidSnapshot {
        let configuration = WKPDFConfiguration()
        configuration.rect = lastRect
        let pdf = try await webView.pdf(configuration: configuration)
        guard let provider = CGDataProvider(data: pdf as CFData),
              let document = CGPDFDocument(provider),
              let page = document.page(at: 1) else {
            throw DrawingError.invalidDiagram("no se pudo convertir en imagen")
        }
        let box = page.getBoxRect(.mediaBox)
        guard box.width > 0, box.height > 0 else {
            throw DrawingError.invalidDiagram("no se pudo convertir en imagen")
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = Self.imageScale
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: box.size, format: format).image { context in
            // PDF y UIKit tienen el eje vertical al revés.
            let cg = context.cgContext
            cg.translateBy(x: -box.minX, y: box.height + box.minY)
            cg.scaleBy(x: 1, y: -1)
            cg.drawPDFPage(page)
        }
        guard let data = image.pngData() else {
            throw DrawingError.invalidDiagram("no se pudo convertir en imagen")
        }
        return MermaidSnapshot(image: data, size: box.size)
    }

    /// Plan B: captura de lo que se ve del diagrama.
    private func visibleImage() async throws -> MermaidSnapshot {
        let configuration = WKSnapshotConfiguration()
        configuration.rect = lastRect
        configuration.afterScreenUpdates = true
        let image = try await webView.takeSnapshot(configuration: configuration)
        guard let data = image.pngData() else {
            throw DrawingError.invalidDiagram("no se pudo convertir en imagen")
        }
        return MermaidSnapshot(image: data, size: image.size)
    }

    // MARK: - Página

    private func waitUntilLoaded() async {
        if isLoaded { return }
        await withCheckedContinuation { continuation in
            loadWaiters.append(continuation)
        }
    }

    private static func number(_ value: Any?) -> CGFloat {
        CGFloat((value as? NSNumber)?.doubleValue ?? 0)
    }

    /// El JavaScript de Mermaid, leído una sola vez del paquete de la app.
    static let mermaidScript: String? = Bundle.main
        .url(forResource: "mermaid.min", withExtension: "js")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) }

    /// Página vacía con un contenedor para el diagrama.
    private static let page = """
    <!doctype html>
    <html>
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      html, body { margin: 0; padding: 0; background: transparent; }
      #diagram { display: inline-block; padding: 16px; }
    </style>
    </head>
    <body><div id="diagram"></div></body>
    </html>
    """

    /// Cuerpo de una función asíncrona de JavaScript (`callAsyncJavaScript`)
    /// con `source` y `theme` como argumentos. Devuelve el recuadro del
    /// diagrama o `{ error }`.
    private static let renderFunction = """
    const id = 'drawpad' + Math.floor(Math.random() * 1000000000);
    const container = document.getElementById('diagram');
    try {
      mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', theme: theme });
      const { svg } = await mermaid.render(id, source);
      container.innerHTML = svg;
      const element = container.querySelector('svg');
      // Tamaño natural del diagrama, no el ancho de la pantalla.
      const box = element.viewBox && element.viewBox.baseVal;
      if (box && box.width > 0 && box.height > 0) {
        element.setAttribute('width', box.width);
        element.setAttribute('height', box.height);
        element.style.maxWidth = 'none';
      }
      const rect = container.getBoundingClientRect();
      return {
        x: rect.left + window.scrollX,
        y: rect.top + window.scrollY,
        width: rect.width,
        height: rect.height
      };
    } catch (error) {
      // Mermaid deja a veces un aviso de error suelto en la página.
      const leftover = document.getElementById('d' + id);
      if (leftover) { leftover.remove(); }
      container.innerHTML = '';
      return { error: String((error && error.message) || error) };
    }
    """
}

extension WebKitMermaidPreview: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
        let waiters = loadWaiters
        loadWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }
}
