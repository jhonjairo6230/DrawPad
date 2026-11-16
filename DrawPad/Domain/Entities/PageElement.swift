import Foundation

/// Algo colocado en una hoja que no es un trazo: un cuadro de texto o una
/// imagen. Se muestra **debajo** de los trazos, para poder dibujar encima.
struct PageElement: Equatable, Identifiable {
    enum Content: Equatable {
        case text(String)
        /// Imagen codificada (PNG o JPEG).
        case image(Data)
    }

    let id: UUID
    /// Hoja a la que pertenece.
    let pageID: UUID
    /// Posición y tamaño en coordenadas de la hoja (las mismas de los trazos).
    /// En un texto, el alto es orientativo: la altura real depende de cuántas
    /// líneas ocupe.
    var frame: CGRect
    var content: Content
    /// Los elementos se apilan por fecha de creación: el más nuevo, encima.
    let createdAt: Date

    var isText: Bool {
        if case .text = content { return true }
        return false
    }
}

/// Medidas que comparten los casos de uso que colocan elementos.
enum PageElementLayout {
    /// Ancho de un cuadro de texto nuevo.
    static let textWidth: CGFloat = 320
    /// Alto orientativo de un cuadro de texto de una línea.
    static let textLineHeight: CGFloat = 28
    /// Lado mínimo de un elemento: más pequeño no se podría volver a tocar.
    static let minimumSide: CGFloat = 40

    /// Un rectángulo de ese tamaño centrado en `center`, sin salirse por
    /// arriba ni por la izquierda de la hoja.
    static func frame(centeredAt center: CGPoint, size: CGSize) -> CGRect {
        CGRect(
            x: max(0, center.x - size.width / 2),
            y: max(0, center.y - size.height / 2),
            width: size.width,
            height: size.height
        )
    }
}
