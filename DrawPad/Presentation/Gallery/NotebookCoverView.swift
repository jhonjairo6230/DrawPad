import SwiftUI

/// Dibuja la tapa de un cuaderno a partir de su color, su estilo y su título.
///
/// La usan la tarjeta de la galería y la vista previa del editor de tapa: una
/// sola vista, para que lo que se elige sea lo que luego se ve.
struct NotebookCoverView: View {
    let title: String
    let cover: NotebookCover

    private let cornerRadius: CGFloat = 14

    var body: some View {
        ZStack {
            Rectangle().fill(cover.color.color.gradient)
            decoration
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius).stroke(.black.opacity(0.15))
        }
        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
    }

    @ViewBuilder
    private var decoration: some View {
        switch cover.style {
        case .plain:
            titleText(color: .white)
                .padding(16)

        case .label:
            VStack {
                titleText(color: .black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(.white, in: RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal, 18)
                    .padding(.top, 36)
                Spacer()
            }

        case .spine:
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.black.opacity(0.28))
                    .frame(width: 22)
                titleText(color: .white)
                    .padding(14)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func titleText(color: Color) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.7)
    }
}
