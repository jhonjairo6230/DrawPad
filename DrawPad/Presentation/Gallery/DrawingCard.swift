import SwiftUI
import UIKit

/// Tarjeta de un dibujo en la galería: miniatura, título y fecha.
struct DrawingCard: View {
    let drawing: DrawingSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnail
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
                // Blanco fijo también en modo oscuro: es "papel", no interfaz.
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12).stroke(.quaternary)
                }

            Text(drawing.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(drawing.updatedAt, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = drawing.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            // Dibujo vacío: todavía no hay miniatura.
            Image(systemName: "scribble.variable")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
