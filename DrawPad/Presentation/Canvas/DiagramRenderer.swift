import UIKit

/// Dibuja figuras y conexiones con Core Graphics. Lo usan la capa de
/// elementos (en pantalla) y la exportación, para que coincidan.
enum DiagramRenderer {
    static let lineWidth: CGFloat = 2.5
    /// Para aproximar un cuarto de elipse con una curva de Bézier.
    private static let kappa: CGFloat = 0.5523

    static func strokeColor(for theme: CanvasTheme) -> UIColor {
        PageElementStyle.textColor(for: theme)
    }

    // MARK: - Figuras

    /// Dibuja la figura y su texto en el contexto gráfico actual.
    static func draw(_ shape: DiagramShape, in rect: CGRect, theme: CanvasTheme) {
        strokeColor(for: theme).setStroke()
        let outline = path(for: shape, in: rect)
        outline.lineWidth = lineWidth
        outline.lineJoinStyle = .round
        outline.stroke()
        drawLabel(shape, in: rect, theme: theme)
    }

    static func path(for shape: DiagramShape, in rect: CGRect) -> UIBezierPath {
        // El trazo se centra en el borde: se encoge para no salirse del marco.
        let r = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        switch shape.kind {
        case .rectangle:
            return UIBezierPath(roundedRect: r, cornerRadius: 6)
        case .ellipse:
            return UIBezierPath(ovalIn: r)
        case .diamond:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: r.midX, y: r.minY))
            path.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            path.addLine(to: CGPoint(x: r.midX, y: r.maxY))
            path.addLine(to: CGPoint(x: r.minX, y: r.midY))
            path.close()
            return path
        case .cylinder:
            return shape.isSideways ? sidewaysCylinder(in: r) : uprightCylinder(in: r)
        }
    }

    /// De pie: elipse completa arriba, laterales y media elipse abajo.
    private static func uprightCylinder(in r: CGRect) -> UIBezierPath {
        let ry = min(r.height * 0.15, r.width * 0.25)
        let path = UIBezierPath(ovalIn: CGRect(x: r.minX, y: r.minY, width: r.width, height: 2 * ry))
        let cx = r.midX
        let cy = r.maxY - ry
        let rx = r.width / 2
        path.move(to: CGPoint(x: r.minX, y: r.minY + ry))
        path.addLine(to: CGPoint(x: r.minX, y: cy))
        path.addCurve(
            to: CGPoint(x: cx, y: cy + ry),
            controlPoint1: CGPoint(x: cx - rx, y: cy + kappa * ry),
            controlPoint2: CGPoint(x: cx - kappa * rx, y: cy + ry)
        )
        path.addCurve(
            to: CGPoint(x: cx + rx, y: cy),
            controlPoint1: CGPoint(x: cx + kappa * rx, y: cy + ry),
            controlPoint2: CGPoint(x: cx + rx, y: cy + kappa * ry)
        )
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY + ry))
        return path
    }

    /// Acostado: elipse completa a la derecha, lados y media elipse a la izquierda.
    private static func sidewaysCylinder(in r: CGRect) -> UIBezierPath {
        let rx = min(r.width * 0.15, r.height * 0.25)
        let path = UIBezierPath(ovalIn: CGRect(x: r.maxX - 2 * rx, y: r.minY, width: 2 * rx, height: r.height))
        let cx = r.minX + rx
        let cy = r.midY
        let ry = r.height / 2
        path.move(to: CGPoint(x: r.maxX - rx, y: r.minY))
        path.addLine(to: CGPoint(x: cx, y: r.minY))
        path.addCurve(
            to: CGPoint(x: cx - rx, y: cy),
            controlPoint1: CGPoint(x: cx - kappa * rx, y: cy - ry),
            controlPoint2: CGPoint(x: cx - rx, y: cy - kappa * ry)
        )
        path.addCurve(
            to: CGPoint(x: cx, y: r.maxY),
            controlPoint1: CGPoint(x: cx - rx, y: cy + kappa * ry),
            controlPoint2: CGPoint(x: cx - kappa * rx, y: r.maxY)
        )
        path.addLine(to: CGPoint(x: r.maxX - rx, y: r.maxY))
        return path
    }

    /// Hueco para el texto: dentro de la figura, sin pisar las tapas del cilindro.
    static func labelRect(for shape: DiagramShape, in rect: CGRect) -> CGRect {
        switch shape.kind {
        case .rectangle:
            return rect.insetBy(dx: 8, dy: 6)
        case .ellipse:
            return rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.15)
        case .diamond:
            return rect.insetBy(dx: rect.width * 0.22, dy: rect.height * 0.22)
        case .cylinder:
            if shape.isSideways {
                let rx = min(rect.width * 0.15, rect.height * 0.25)
                return CGRect(x: rect.minX + rx, y: rect.minY, width: rect.width - 3 * rx, height: rect.height)
                    .insetBy(dx: 4, dy: 6)
            }
            let ry = min(rect.height * 0.15, rect.width * 0.25)
            return CGRect(x: rect.minX, y: rect.minY + 2 * ry, width: rect.width, height: rect.height - 3 * ry)
                .insetBy(dx: 6, dy: 4)
        }
    }

    private static func drawLabel(_ shape: DiagramShape, in rect: CGRect, theme: CanvasTheme) {
        guard !shape.label.isEmpty else { return }
        let area = labelRect(for: shape, in: rect)
        guard area.width > 0, area.height > 0 else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        var attributes = PageElementStyle.attributes(for: theme)
        attributes[.paragraphStyle] = paragraph
        let text = shape.label as NSString
        let height = min(
            area.height,
            ceil(text.boundingRect(
                with: CGSize(width: area.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            ).height)
        )
        // Centrado también en vertical.
        let textRect = CGRect(x: area.minX, y: area.midY - height / 2, width: area.width, height: height)
        text.draw(
            with: textRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine],
            attributes: attributes,
            context: nil
        )
    }

    // MARK: - Conexiones

    /// Dibuja los tramos en el contexto gráfico actual. El seleccionado, en azul.
    static func draw(_ segments: [DiagramGeometry.Segment], theme: CanvasTheme, highlighted: UUID? = nil) {
        for segment in segments {
            let color = segment.connectorID == highlighted ? UIColor.systemBlue : strokeColor(for: theme)
            color.setStroke()
            let path = UIBezierPath()
            path.lineWidth = segment.connectorID == highlighted ? lineWidth + 1.5 : lineWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.move(to: segment.start)
            path.addLine(to: segment.end)
            if segment.style == .arrow,
               let head = DiagramGeometry.arrowHead(at: segment.end, from: segment.start) {
                path.move(to: head.left)
                path.addLine(to: segment.end)
                path.addLine(to: head.right)
            }
            path.stroke()
        }
    }
}
