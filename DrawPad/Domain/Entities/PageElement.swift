import Foundation

/// Algo colocado en una hoja que no es un trazo: un cuadro de texto, una
/// imagen, una figura de diagrama o una conexión entre figuras. Se muestra
/// **debajo** de los trazos, para poder dibujar encima.
struct PageElement: Equatable, Identifiable {
    enum Content: Equatable {
        case text(String)
        /// Imagen codificada (PNG o JPEG).
        case image(Data)
        /// Figura de diagrama (rectángulo, círculo, rombo, cilindro).
        case shape(DiagramShape)
        /// Flecha o línea entre dos elementos. No tiene posición propia: se
        /// dibuja entre los bordes de los elementos que une y los sigue al
        /// moverlos. Su `frame` es `.zero`.
        case connector(Connector)
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

    var isShape: Bool {
        if case .shape = content { return true }
        return false
    }

    var isConnector: Bool {
        if case .connector = content { return true }
        return false
    }

    /// `true` si es una conexión que llega o sale de `elementID`.
    func connects(_ elementID: UUID) -> Bool {
        guard case .connector(let connector) = content else { return false }
        return connector.fromID == elementID || connector.toID == elementID
    }
}

/// Una figura de diagrama, con su texto centrado y su giro.
struct DiagramShape: Equatable {
    var kind: ShapeKind
    /// Texto centrado dentro de la figura; vacío si no tiene.
    var label: String = ""
    /// Giro en cuartos de vuelta (0 a 3). En un cilindro, uno o tres cuartos
    /// lo dejan acostado (por ejemplo, una cola de mensajes).
    var quarterTurns: Int = 0

    /// `true` si está acostada (90° o 270°).
    var isSideways: Bool { quarterTurns % 2 == 1 }
}

/// Las figuras disponibles. El `rawValue` es lo que se guarda en la base de
/// datos: no se cambia aunque se renombren los casos.
enum ShapeKind: String, CaseIterable, Equatable {
    case rectangle
    case ellipse
    case diamond
    /// Base de datos de pie; acostado, una cola de mensajes.
    case cylinder

    /// Tamaño con el que se inserta, de pie.
    var defaultSize: CGSize {
        switch self {
        case .rectangle: return CGSize(width: 160, height: 100)
        case .ellipse: return CGSize(width: 120, height: 120)
        case .diamond: return CGSize(width: 150, height: 110)
        case .cylinder: return CGSize(width: 110, height: 140)
        }
    }
}

/// Flecha o línea entre dos elementos de la misma hoja.
struct Connector: Equatable {
    let fromID: UUID
    let toID: UUID
    var style: ConnectorStyle
}

/// El `rawValue` es lo que se guarda en la base de datos.
enum ConnectorStyle: String, CaseIterable, Equatable {
    /// Con punta en el extremo de destino.
    case arrow
    /// Sin punta.
    case line
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
