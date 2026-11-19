import XCTest
@testable import DrawPad

final class CanvasGeometryTests: XCTestCase {
    private let viewport = CGSize(width: 800, height: 600)

    // MARK: - Tamaño de la hoja

    func testAnEmptyDrawingUsesTheViewportAsPage() {
        XCTAssertEqual(CanvasGeometry.pageSize(viewport: viewport, drawingBounds: nil), viewport)
        XCTAssertEqual(CanvasGeometry.pageSize(viewport: viewport, drawingBounds: .null), viewport)
    }

    func testStrokesInsideTheViewportDoNotGrowThePage() {
        let bounds = CGRect(x: 100, y: 100, width: 200, height: 200)

        XCTAssertEqual(CanvasGeometry.pageSize(viewport: viewport, drawingBounds: bounds), viewport)
    }

    func testStrokesBeyondTheViewportGrowThePageToReachThem() {
        // Dibujado en horizontal y visto ahora en vertical.
        let bounds = CGRect(x: 700, y: 500, width: 400, height: 300)

        XCTAssertEqual(
            CanvasGeometry.pageSize(viewport: viewport, drawingBounds: bounds),
            CGSize(width: 1100, height: 800)
        )
    }

    func testThePageCanGrowInOnlyOneDirection() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 100)

        XCTAssertEqual(
            CanvasGeometry.pageSize(viewport: viewport, drawingBounds: bounds),
            CGSize(width: 1000, height: 600)
        )
    }

    // MARK: - Contenido y papel

    func testContentSizeIsThePageScaledByTheZoom() {
        XCTAssertEqual(
            CanvasGeometry.contentSize(pageSize: viewport, zoomScale: 2),
            CGSize(width: 1600, height: 1200)
        )
    }

    func testPaperIsCenteredOnThePageWithoutZoomOrScroll() {
        let center = CanvasGeometry.paperCenter(pageSize: viewport, zoomScale: 1, contentOffset: .zero)

        XCTAssertEqual(center, CGPoint(x: 400, y: 300))
    }

    func testPaperFollowsZoomAndScroll() {
        let center = CanvasGeometry.paperCenter(
            pageSize: viewport,
            zoomScale: 2,
            contentOffset: CGPoint(x: 300, y: 100)
        )

        // La hoja ampliada mide 1600 × 1200; su centro (800, 600) se ve
        // desplazado 300 a la izquierda y 100 hacia arriba.
        XCTAssertEqual(center, CGPoint(x: 500, y: 500))
    }

    // MARK: - Centro visible y contenido

    func testVisibleCenterWithoutZoomIsTheMiddleOfTheViewport() {
        let center = CanvasGeometry.visibleCenter(viewport: viewport, zoomScale: 1, contentOffset: .zero)

        XCTAssertEqual(center, CGPoint(x: 400, y: 300))
    }

    func testVisibleCenterAccountsForZoomAndScroll() {
        let center = CanvasGeometry.visibleCenter(
            viewport: viewport,
            zoomScale: 2,
            contentOffset: CGPoint(x: 300, y: 100)
        )

        // En pantalla, el centro está en (300 + 400, 100 + 300); a 2× eso es
        // el punto (350, 200) de la hoja.
        XCTAssertEqual(center, CGPoint(x: 350, y: 200))
    }

    func testContentBoundsIsNilForAnEmptyPage() {
        XCTAssertNil(CanvasGeometry.contentBounds(strokes: nil, elements: []))
        XCTAssertNil(CanvasGeometry.contentBounds(strokes: .null, elements: []))
    }

    func testContentBoundsCoversStrokesAndElements() {
        let strokes = CGRect(x: 100, y: 100, width: 50, height: 50)
        let far = CGRect(x: 900, y: 20, width: 100, height: 40)

        XCTAssertEqual(
            CanvasGeometry.contentBounds(strokes: strokes, elements: [far]),
            CGRect(x: 100, y: 20, width: 900, height: 130)
        )
        XCTAssertEqual(CanvasGeometry.contentBounds(strokes: nil, elements: [far]), far)
    }

    func testAnElementBeyondTheViewportGrowsThePage() {
        let bounds = CanvasGeometry.contentBounds(
            strokes: nil,
            elements: [CGRect(x: 900, y: 500, width: 200, height: 300)]
        )

        XCTAssertEqual(
            CanvasGeometry.pageSize(viewport: viewport, drawingBounds: bounds),
            CGSize(width: 1100, height: 800)
        )
    }

    // MARK: - Ajustar al ancho (solo lectura)

    func testAWidePageIsZoomedOutToFitTheWidth() {
        let phone = CGSize(width: 390, height: 700)
        let ipadPage = CGSize(width: 1170, height: 1400)

        XCTAssertEqual(CanvasGeometry.fitWidthZoom(viewport: phone, pageSize: ipadPage), 1.0 / 3.0, accuracy: 0.0001)
    }

    func testANarrowPageIsNeverEnlarged() {
        XCTAssertEqual(CanvasGeometry.fitWidthZoom(viewport: viewport, pageSize: CGSize(width: 400, height: 300)), 1)
    }

    func testFitWidthWithoutSizesIsOne() {
        XCTAssertEqual(CanvasGeometry.fitWidthZoom(viewport: .zero, pageSize: viewport), 1)
        XCTAssertEqual(CanvasGeometry.fitWidthZoom(viewport: viewport, pageSize: .zero), 1)
    }

    func testZoomLimitsAllowZoomingInButNotOut() {
        XCTAssertEqual(CanvasGeometry.minimumZoom, 1)
        XCTAssertGreaterThan(CanvasGeometry.maximumZoom, 1)
    }
}
