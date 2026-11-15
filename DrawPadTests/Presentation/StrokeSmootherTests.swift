import XCTest
@testable import DrawPad

final class StrokeSmootherTests: XCTestCase {
    /// Línea horizontal con un temblor vertical de ±`amplitude`.
    private func zigzag(points: Int = 9, amplitude: CGFloat = 10) -> [CGPoint] {
        (0..<points).map { index in
            CGPoint(x: CGFloat(index) * 10, y: index.isMultiple(of: 2) ? 0 : amplitude)
        }
    }

    /// El mayor salto vertical entre dos puntos vecinos: cuánto "tiembla".
    ///
    /// No se mide la distancia al eje: un zigzag entre 0 y 10 no se aplana
    /// hacia 0, sino hacia su línea media (5).
    private func roughness(_ points: [CGPoint]) -> CGFloat {
        zip(points, points.dropFirst()).map { abs($1.y - $0.y) }.max() ?? 0
    }

    func testAStraightLineDoesNotChange() {
        let line = (0..<6).map { CGPoint(x: CGFloat($0) * 10, y: CGFloat($0) * 5) }

        let smoothed = StrokeSmoother.smooth(line)

        for (original, result) in zip(line, smoothed) {
            XCTAssertEqual(result.x, original.x, accuracy: 0.0001)
            XCTAssertEqual(result.y, original.y, accuracy: 0.0001)
        }
    }

    func testEndpointsStayWhereTheUserPutThem() {
        let line = zigzag()

        let smoothed = StrokeSmoother.smooth(line, passes: 5)

        XCTAssertEqual(smoothed.first, line.first)
        XCTAssertEqual(smoothed.last, line.last)
    }

    func testThePointCountIsPreserved() {
        XCTAssertEqual(StrokeSmoother.smooth(zigzag(points: 12)).count, 12)
    }

    func testAZigzagGetsFlatter() {
        let line = zigzag(amplitude: 10)

        let smoothed = StrokeSmoother.smooth(line, passes: 1)

        // Un pico de 10 entre dos vecinos a 0 baja a (0 + 2·10 + 0) / 4 = 5,
        // y un valle de 0 entre dos picos sube a (10 + 0 + 10) / 4 = 5.
        XCTAssertEqual(smoothed[1].y, 5, accuracy: 0.0001)
        XCTAssertEqual(smoothed[2].y, 5, accuracy: 0.0001)
        XCTAssertLessThan(roughness(smoothed), roughness(line))
    }

    func testMorePassesSmoothMore() {
        let line = zigzag()

        let once = StrokeSmoother.smooth(line, passes: 1)
        let fourTimes = StrokeSmoother.smooth(line, passes: 4)

        XCTAssertLessThan(roughness(fourTimes), roughness(once))
    }

    func testHorizontalPositionsOfAnEvenlySpacedLineDoNotMove() {
        let line = zigzag()

        let smoothed = StrokeSmoother.smooth(line)

        for (original, result) in zip(line, smoothed) {
            XCTAssertEqual(result.x, original.x, accuracy: 0.0001)
        }
    }

    func testLinesTooShortToSmoothAreReturnedAsIs() {
        let dot = [CGPoint(x: 1, y: 1)]
        let segment = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10)]

        XCTAssertEqual(StrokeSmoother.smooth([]), [])
        XCTAssertEqual(StrokeSmoother.smooth(dot), dot)
        XCTAssertEqual(StrokeSmoother.smooth(segment), segment)
    }

    func testZeroPassesChangeNothing() {
        let line = zigzag()

        XCTAssertEqual(StrokeSmoother.smooth(line, passes: 0), line)
    }
}
