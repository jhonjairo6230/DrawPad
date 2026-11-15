import XCTest
@testable import DrawPad

final class StrokeSmootherTests: XCTestCase {
    /// Línea horizontal con un temblor vertical de ±`amplitude`.
    private func zigzag(points: Int = 9, amplitude: CGFloat = 10) -> [CGPoint] {
        (0..<points).map { index in
            CGPoint(x: CGFloat(index) * 10, y: index.isMultiple(of: 2) ? 0 : amplitude)
        }
    }

    /// Cuánto se aparta la línea, como máximo, de la recta entre sus extremos
    /// (aquí, del eje `y = 0`).
    private func wobble(_ points: [CGPoint]) -> CGFloat {
        points.dropFirst().dropLast().map { abs($0.y) }.max() ?? 0
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

        // Un pico de 10 entre dos vecinos a 0 baja a (0 + 2·10 + 0) / 4 = 5.
        XCTAssertEqual(smoothed[1].y, 5, accuracy: 0.0001)
        XCTAssertLessThan(wobble(smoothed), wobble(line))
    }

    func testMorePassesSmoothMore() {
        let line = zigzag()

        let once = StrokeSmoother.smooth(line, passes: 1)
        let fourTimes = StrokeSmoother.smooth(line, passes: 4)

        XCTAssertLessThan(wobble(fourTimes), wobble(once))
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
