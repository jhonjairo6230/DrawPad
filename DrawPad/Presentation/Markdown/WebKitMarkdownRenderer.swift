import UIKit
import WebKit

/// Muestra Markdown formateado con WebKit, la librería marked y, para los
/// bloques ```mermaid, la librería Mermaid; las dos van dentro de la app.
///
/// - **Sin conexión:** los scripts se leen del paquete de la app y la página
///   se carga desde texto. El documento no sale del dispositivo.
/// - **HTML del documento como texto:** si el Markdown trae HTML (por
///   ejemplo, un `.md` importado con `<script>`), se muestra escapado en vez
///   de ejecutarse.
/// - **Enlaces:** se abren en Safari, no dentro de la hoja.
/// - **Modo oscuro:** la página sigue el aspecto del sistema.
///
/// Es, con ``WebKitMermaidPreview``, de los pocos sitios que conocen WebKit
/// (ver docs/adr/0020).
@MainActor
final class WebKitMarkdownRenderer: NSObject {
    /// Versión de marked incluida en la app.
    static let markedVersion = "18.2.1"

    let webView: WKWebView
    private var isLoaded = false
    private var loadWaiters: [CheckedContinuation<Void, Never>] = []
    /// Último texto mostrado, para no volver a formatear lo mismo.
    private var shownText: String?
    private var pendingShow: Task<Void, Never>?

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let scripts = [Self.markedScript, WebKitMermaidPreview.mermaidScript, Self.setupScript].compactMap { $0 }
        for script in scripts {
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

    /// Muestra este texto (si no es el que ya se ve). No espera al resultado.
    func show(_ markdown: String) {
        guard markdown != shownText else { return }
        shownText = markdown
        pendingShow?.cancel()
        pendingShow = Task { [weak self] in
            await self?.waitUntilLoaded()
            // Mientras cargaba la página llegó un texto más nuevo.
            guard !Task.isCancelled else { return }
            _ = await self?.render(markdown)
        }
    }

    /// Formatea el texto y devuelve qué se dibujó (para las pruebas), o `nil`
    /// si falló el propio formateo.
    @discardableResult
    func render(_ markdown: String) async -> MarkdownRenderSummary? {
        guard Self.markedScript != nil else { return nil }
        await waitUntilLoaded()
        do {
            let result = try await webView.callAsyncJavaScript(
                Self.renderFunction,
                arguments: ["source": markdown],
                in: nil,
                contentWorld: .page
            )
            guard let values = result as? [String: Any] else { return nil }
            func count(_ key: String) -> Int { (values[key] as? NSNumber)?.intValue ?? 0 }
            return MarkdownRenderSummary(
                headings: count("headings"),
                tables: count("tables"),
                taskItems: count("taskItems"),
                diagrams: count("diagrams"),
                diagramErrors: count("diagramErrors"),
                scripts: count("scripts")
            )
        } catch {
            return nil
        }
    }

    private func waitUntilLoaded() async {
        if isLoaded { return }
        await withCheckedContinuation { continuation in
            loadWaiters.append(continuation)
        }
    }

    // MARK: - Scripts y página

    /// marked, leído una sola vez del paquete de la app.
    static let markedScript: String? = Bundle.main
        .url(forResource: "marked.umd", withExtension: "js")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) }

    /// Configura marked una vez: Markdown de GitHub y el HTML del documento
    /// convertido en texto.
    private static let setupScript = """
    (function () {
      if (typeof marked === 'undefined') { return; }
      const escapeHtml = (text) => String(text)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      marked.use({
        gfm: true,
        renderer: {
          html(token) { return escapeHtml(token.text || token.raw || ''); }
        }
      });
    })();
    """

    /// Cuerpo de una función asíncrona con `source` como argumento.
    ///
    /// Cada llamada se numera: si mientras se dibuja un diagrama llega un
    /// texto más nuevo, la anterior se detiene y no toca la página.
    private static let renderFunction = """
    const generation = (window.drawpadRenderGeneration || 0) + 1;
    window.drawpadRenderGeneration = generation;
    const isStale = () => window.drawpadRenderGeneration !== generation;
    const content = document.getElementById('content');
    const draft = document.createElement('div');
    draft.innerHTML = marked.parse(source);
    let diagrams = 0;
    let diagramErrors = 0;
    if (typeof mermaid !== 'undefined') {
      const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', theme: dark ? 'dark' : 'default' });
      const blocks = Array.from(draft.querySelectorAll('pre > code.language-mermaid'));
      for (let index = 0; index < blocks.length; index++) {
        const code = blocks[index];
        const id = 'mdmermaid' + index + '_' + Math.floor(Math.random() * 1000000000);
        const holder = document.createElement('div');
        try {
          const { svg } = await mermaid.render(id, code.textContent);
          holder.className = 'mermaid-diagram';
          holder.innerHTML = svg;
          diagrams++;
        } catch (error) {
          const leftover = document.getElementById('d' + id);
          if (leftover) { leftover.remove(); }
          holder.className = 'mermaid-error';
          holder.textContent = 'Error en el diagrama: ' + String((error && error.message) || error);
          diagramErrors++;
        }
        if (isStale()) { return null; }
        code.parentElement.replaceWith(holder);
      }
    }
    if (isStale()) { return null; }
    // El documento se cambia de una vez, ya con los diagramas dibujados.
    content.replaceChildren(...draft.childNodes);
    return {
      headings: content.querySelectorAll('h1, h2, h3, h4, h5, h6').length,
      tables: content.querySelectorAll('table').length,
      taskItems: content.querySelectorAll('input[type="checkbox"]').length,
      diagrams: diagrams,
      diagramErrors: diagramErrors,
      scripts: content.querySelectorAll('script').length
    };
    """

    /// Página con estilos parecidos a los de GitHub, en claro y oscuro.
    private static let page = """
    <!doctype html>
    <html>
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      :root { color-scheme: light dark; }
      body {
        margin: 0; padding: 24px 28px 64px;
        font: -apple-system-body; font-family: -apple-system, sans-serif;
        line-height: 1.55; color: #1f2328; background: transparent;
        word-wrap: break-word;
      }
      h1, h2 { border-bottom: 1px solid #d0d7de; padding-bottom: .3em; }
      h1, h2, h3, h4 { margin-top: 1.4em; margin-bottom: .6em; line-height: 1.25; }
      a { color: #0969da; }
      code { font-family: ui-monospace, Menlo, monospace; font-size: 90%;
             background: rgba(175, 184, 193, .2); padding: .15em .35em; border-radius: 6px; }
      pre { background: #f6f8fa; padding: 14px; border-radius: 8px; overflow-x: auto; }
      pre code { background: none; padding: 0; }
      blockquote { margin: 0; padding: 0 1em; color: #59636e; border-left: .25em solid #d0d7de; }
      table { border-collapse: collapse; display: block; overflow-x: auto; }
      th, td { border: 1px solid #d0d7de; padding: 6px 13px; }
      tr:nth-child(2n) { background: #f6f8fa; }
      img { max-width: 100%; }
      ul.contains-task-list, li.task-list-item { list-style: none; }
      .mermaid-diagram { margin: 1em 0; overflow-x: auto; }
      .mermaid-error { color: #cf222e; font-size: 90%; margin: 1em 0; }
      @media (prefers-color-scheme: dark) {
        body { color: #e6edf3; }
        h1, h2 { border-bottom-color: #3d444d; }
        a { color: #4493f8; }
        pre, tr:nth-child(2n) { background: #151b23; }
        blockquote { color: #9198a1; border-left-color: #3d444d; }
        th, td { border-color: #3d444d; }
        .mermaid-error { color: #f85149; }
      }
    </style>
    </head>
    <body><article id="content"></article></body>
    </html>
    """
}

/// Qué se dibujó al formatear un documento. Lo usan las pruebas.
struct MarkdownRenderSummary: Equatable {
    let headings: Int
    let tables: Int
    let taskItems: Int
    let diagrams: Int
    let diagramErrors: Int
    /// `<script>` que llegaron a la página (debe ser 0: el HTML se escapa).
    let scripts: Int
}

extension WebKitMarkdownRenderer: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
        let waiters = loadWaiters
        loadWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    /// Los enlaces del documento se abren fuera (Safari, Mail); los saltos a
    /// una sección del propio documento se quedan.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.navigationType == .linkActivated,
              let url = navigationAction.request.url,
              url.scheme != "about" else {
            decisionHandler(.allow)
            return
        }
        if ["http", "https", "mailto"].contains(url.scheme?.lowercased() ?? "") {
            UIApplication.shared.open(url)
        }
        decisionHandler(.cancel)
    }
}
