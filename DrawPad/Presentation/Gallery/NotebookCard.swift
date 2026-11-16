import SwiftUI
import UIKit

/// Tarjeta de un cuaderno en la galería: portada, título, hojas y fecha.
struct NotebookCard: View {
    let notebook: NotebookSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cover
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
                // Blanco fijo también en modo oscuro: es "papel", no interfaz.
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12).stroke(.quaternary)
                }

            Text(notebook.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(pageCountText)
                Text("·")
                Text(notebook.lastActivityAt, format: .relative(presentation: .named))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var pageCountText: String {
        notebook.pageCount == 1 ? "1 hoja" : "\(notebook.pageCount) hojas"
    }

    /// La primera hoja del cuaderno hace de portada.
    @ViewBuilder
    private var cover: some View {
        if let data = notebook.coverThumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            // Primera hoja vacía: todavía no hay miniatura.
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
