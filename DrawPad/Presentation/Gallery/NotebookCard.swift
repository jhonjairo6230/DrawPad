import SwiftUI

/// Tarjeta de un cuaderno en la galería: su tapa, el número de hojas y la fecha.
///
/// El título va dentro de la tapa (``NotebookCoverView``), no debajo.
struct NotebookCard: View {
    let notebook: NotebookSummary

    var body: some View {
        VStack(spacing: 8) {
            NotebookCoverView(title: notebook.title, cover: notebook.cover)

            HStack(spacing: 4) {
                Text(pageCountText)
                Text("·")
                Text(notebook.lastActivityAt, format: .relative(presentation: .named))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
    }

    private var pageCountText: String {
        notebook.pageCount == 1 ? "1 hoja" : "\(notebook.pageCount) hojas"
    }
}
