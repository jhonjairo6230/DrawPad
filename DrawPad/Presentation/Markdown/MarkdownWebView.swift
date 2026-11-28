import SwiftUI
import WebKit

/// Muestra en SwiftUI la vista web de ``WebKitMarkdownRenderer`` con este texto.
struct MarkdownWebView: UIViewRepresentable {
    let renderer: WebKitMarkdownRenderer
    let markdown: String

    func makeUIView(context: Context) -> WKWebView {
        renderer.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        renderer.show(markdown)
    }
}
