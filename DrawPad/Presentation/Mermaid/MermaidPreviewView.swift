import SwiftUI
import WebKit

/// Muestra en SwiftUI la vista web de ``WebKitMermaidPreview``.
struct MermaidPreviewView: UIViewRepresentable {
    let preview: WebKitMermaidPreview

    func makeUIView(context: Context) -> WKWebView {
        preview.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
