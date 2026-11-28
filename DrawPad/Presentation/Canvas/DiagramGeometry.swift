import CoreGraphics
import Foundation

/// Las cuentas de las conexiones entre elementos, sin UIKit, para poder
/// probarlas con números.
///
/// Una flecha va **de borde a borde**: sale del borde del primer elemento en
/// dirección al centro del segundo y termina en el borde del segundo. Así, al
/// mover o girar una figura, la flecha se recalcula sola.
enum DiagramGeometry {
    /// Contorno con el que se corta una conexión. El cilindro y el texto se
    /// tratan como cajas.
    enum Outline: Equatable {
        case box
        case ellipse
        case diamond
    }

    /// Un tramo listo para dibujar.
    struct Segment: Equatable {
        let connectorID: UUID
        let start: CGPoint
        let end: CGPoint
        let style: ConnectorStyle
    }

    static func outline(of content: PageElement.Content) -> Outline {
        guard case .shape(let shape) = content else { return .box }
        switch shape.kind {
        case .ellipse: return .ellipse
        case .diamond: return .diamond
        case .rectangle, .cylinder: return .box
        }
    }

    /// Qué fracción de `direction`, medida desde el centro de `rect`, hay que
    /// recorrer para llegar a su contorno.
    static func boundaryFraction(of rect: CGRect, outline: Outline, direction: CGVector) -> CGFloat {
        let halfWidth = rect.width / 2
        let halfHeight = rect.height / 2
        guard halfWidth > 0, halfHeight > 0 else { return 0 }
        let x = abs(direction.dx) / halfWidth
        let y = abs(direction.dy) / halfHeight
        let measure: CGFloat
        switch outline {
        case .box: measure = max(x, y)
        case .ellipse: measure = (x * x + y * y).squareRoot()
        case .diamond: measure = x + y
        }
        return measure > 0 ? 1 / measure : 0
    }

    /// Dónde empieza y acaba la línea entre dos elementos, o `nil` si se tocan
    /// o se solapan (no hay hueco donde dibujarla).
    static func endpoints(
        from: CGRect, fromOutline: Outline,
        to: CGRect, toOutline: Outline
    ) -> (start: CGPoint, end: CGPoint)? {
        let fromCenter = CGPoint(x: from.midX, y: from.midY)
        let toCenter = CGPoint(x: to.midX, y: to.midY)
        let direction = CGVector(dx: toCenter.x - fromCenter.x, dy: toCenter.y - fromCenter.y)
        guard direction.dx != 0 || direction.dy != 0 else { return nil }
        let leaving = boundaryFraction(of: from, outline: fromOutline, direction: direction)
        let arriving = boundaryFraction(of: to, outline: toOutline, direction: direction)
        guard leaving + arriving < 1 else { return nil }
        return (
            CGPoint(x: fromCenter.x + direction.dx * leaving, y: fromCenter.y + direction.dy * leaving),
            CGPoint(x: toCenter.x - direction.dx * arriving, y: toCenter.y - direction.dy * arriving)
        )
    }

    /// Los tramos de todas las conexiones de `elements`.
    /// - Parameter frames: el marco **visible** de cada elemento que no es una
    ///   conexión (en un texto, con su alto real).
    static func segments(for elements: [PageElement], frames: [UUID: CGRect]) -> [Segment] {
        let byID = Dictionary(uniqueKeysWithValues: elements.map { ($0.id, $0) })
        return elements.compactMap { element in
            guard case .connector(let connector) = element.content,
                  let from = byID[connector.fromID], let to = byID[connector.toID],
                  let fromFrame = frames[connector.fromID], let toFrame = frames[connector.toID],
                  let ends = endpoints(
                      from: fromFrame, fromOutline: outline(of: from.content),
                      to: toFrame, toOutline: outline(of: to.content)
                  ) else { return nil }
            return Segment(connectorID: element.id, start: ends.start, end: ends.end, style: connector.style)
        }
    }

    /// Las dos puntas de la cabeza de una flecha que acaba en `end`.
    static func arrowHead(
        at end: CGPoint, from start: CGPoint,
        length: CGFloat = 16, spread: CGFloat = .pi / 7
    ) -> (left: CGPoint, right: CGPoint)? {
        let dx = end.x - start.x
        let dy = end.y - start.y
        guard dx != 0 || dy != 0 else { return nil }
        let angle = atan2(dy, dx)
        return (
            CGPoint(x: end.x - length * cos(angle - spread), y: end.y - length * sin(angle - spread)),
            CGPoint(x: end.x - length * cos(angle + spread), y: end.y - length * sin(angle + spread))
        )
    }

    /// Distancia de un punto a un tramo: para saber si un toque cae sobre una
    /// conexión.
    static func distance(from point: CGPoint, toSegmentFrom a: CGPoint, to b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(point.x - a.x, point.y - a.y) }
        let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared))
        return hypot(point.x - (a.x + t * dx), point.y - (a.y + t * dy))
    }
}
