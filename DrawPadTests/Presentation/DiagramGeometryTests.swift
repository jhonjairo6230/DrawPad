import XCTest
@testable import DrawPad

final class DiagramGeometryTests: XCTestCase {
    private func assertPoint(
        _ point: CGPoint, _ expected: CGPoint,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual(point.x, expected.x, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(point.y, expected.y, accuracy: 0.001, file: file, line: line)
    }

    // MARK: - Contorno

    func testOutlineDependsOnTheShape() {
        XCTAssertEqual(DiagramGeometry.outline(of: .shape(DiagramShape(kind: .ellipse))), .ellipse)
        XCTAssertEqual(DiagramGeometry.outline(of: .shape(DiagramShape(kind: .diamond))), .diamond)
        XCTAssertEqual(DiagramGeometry.outline(of: .shape(DiagramShape(kind: .cylinder))), .box)
        XCTAssertEqual(DiagramGeometry.outline(of: .text("Hola")), .box)
    }

    func testBoundaryOfABoxGoingRightIsItsHalfWidth() {
        let box = CGRect(x: 0, y: 0, width: 100, height: 40)

        // Hacia la derecha 200 puntos: el borde está a 50, la cuarta parte.
        let t = DiagramGeometry.boundaryFraction(of: box, outline: .box, direction: CGVector(dx: 200, dy: 0))

        XCTAssertEqual(t, 0.25, accuracy: 0.0001)
    }

    func testBoundaryOfAnEllipseAndADiamondOnTheDiagonal() {
        let square = CGRect(x: 0, y: 0, width: 100, height: 100)
        let diagonal = CGVector(dx: 100, dy: 100)

        let ellipse = DiagramGeometry.boundaryFraction(of: square, outline: .ellipse, direction: diagonal)
        let diamond = DiagramGeometry.boundaryFraction(of: square, outline: .diamond, direction: diagonal)
        let box = DiagramGeometry.boundaryFraction(of: square, outline: .box, direction: diagonal)

        // En la diagonal, el rombo queda más cerca del centro que el círculo,
        // y el círculo más cerca que la caja.
        XCTAssertEqual(diamond, 0.25, accuracy: 0.0001)
        XCTAssertEqual(ellipse, 0.5 / CGFloat(2).squareRoot(), accuracy: 0.0001)
        XCTAssertEqual(box, 0.5, accuracy: 0.0001)
    }

    // MARK: - Extremos

    func testAConnectionGoesFromEdgeToEdge() {
        let left = CGRect(x: 0, y: 0, width: 100, height: 100)
        let right = CGRect(x: 300, y: 0, width: 100, height: 100)

        let ends = DiagramGeometry.endpoints(from: left, fromOutline: .box, to: right, toOutline: .box)

        assertPoint(ends!.start, CGPoint(x: 100, y: 50))
        assertPoint(ends!.end, CGPoint(x: 300, y: 50))
    }

    func testAConnectionToACircleStopsAtTheCircle() {
        let box = CGRect(x: 0, y: 0, width: 100, height: 100)
        let circle = CGRect(x: 0, y: 300, width: 100, height: 100)

        let ends = DiagramGeometry.endpoints(from: box, fromOutline: .box, to: circle, toOutline: .ellipse)

        assertPoint(ends!.start, CGPoint(x: 50, y: 100))
        assertPoint(ends!.end, CGPoint(x: 50, y: 300))
    }

    func testOverlappingElementsHaveNoConnectionToDraw() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 50, y: 0, width: 100, height: 100)

        XCTAssertNil(DiagramGeometry.endpoints(from: a, fromOutline: .box, to: b, toOutline: .box))
        XCTAssertNil(DiagramGeometry.endpoints(from: a, fromOutline: .box, to: a, toOutline: .box))
    }

    func testSegmentsFollowTheCurrentFramesAndSkipBrokenConnections() {
        let pageID = UUID()
        let a = PageElement.sampleShape(pageID: pageID, .rectangle)
        let b = PageElement.sampleShape(pageID: pageID, .cylinder)
        let good = PageElement.sampleConnector(pageID: pageID, from: a.id, to: b.id, style: .line)
        let broken = PageElement.sampleConnector(pageID: pageID, from: a.id, to: UUID())
        let frames = [
            a.id: CGRect(x: 0, y: 0, width: 100, height: 100),
            b.id: CGRect(x: 300, y: 0, width: 100, height: 100),
        ]

        let segments = DiagramGeometry.segments(for: [a, b, good, broken], frames: frames)

        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments.first?.connectorID, good.id)
        XCTAssertEqual(segments.first?.style, .line)
        assertPoint(segments[0].start, CGPoint(x: 100, y: 50))
        assertPoint(segments[0].end, CGPoint(x: 300, y: 50))
    }

    // MARK: - Flecha y toques

    func testTheArrowHeadPointsBackFromTheEnd() {
        let head = DiagramGeometry.arrowHead(
            at: CGPoint(x: 100, y: 0), from: .zero, length: 10, spread: .pi / 4
        )!

        // Una flecha hacia la derecha: las puntas quedan detrás del extremo,
        // una arriba y otra abajo, simétricas.
        XCTAssertLessThan(head.left.x, 100)
        XCTAssertLessThan(head.right.x, 100)
        XCTAssertEqual(head.left.x, head.right.x, accuracy: 0.0001)
        XCTAssertEqual(head.left.y, -head.right.y, accuracy: 0.0001)
        XCTAssertNil(DiagramGeometry.arrowHead(at: .zero, from: .zero))
    }

    func testDistanceToASegment() {
        let a = CGPoint(x: 0, y: 0)
        let b = CGPoint(x: 100, y: 0)

        XCTAssertEqual(DiagramGeometry.distance(from: CGPoint(x: 50, y: 10), toSegmentFrom: a, to: b), 10, accuracy: 0.0001)
        // Más allá de un extremo, la distancia es al extremo.
        XCTAssertEqual(DiagramGeometry.distance(from: CGPoint(x: 103, y: 4), toSegmentFrom: a, to: b), 5, accuracy: 0.0001)
        XCTAssertEqual(DiagramGeometry.distance(from: CGPoint(x: 3, y: 4), toSegmentFrom: a, to: a), 5, accuracy: 0.0001)
    }
}
