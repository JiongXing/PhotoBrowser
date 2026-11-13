import XCTest
@testable import RotationHost

@MainActor
final class ZoomTests: XCTestCase {
    var window: UIWindow!
    var cell: JXZoomImageCell!

    override func setUp() {
        super.setUp()
        window = UIWindow(windowScene: UIApplication.shared.connectedScenes.first as! UIWindowScene)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        cell = JXZoomImageCell(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController!.view.addSubview(cell)
        setImage(CGSize(width: 600, height: 400))
    }

    override func tearDown() {
        window.isHidden = true
        window.rootViewController = nil
        cell = nil
        window = nil
        super.tearDown()
    }

    func setImage(_ size: CGSize) {
        cell.imageView.image = UIGraphicsImageRenderer(size: size).image { _ in }
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
    }

    func doubleTap() {
        cell.handleDoubleTap(cell.doubleTapGesture)
        let settled = expectation(description: "zoom animation settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { settled.fulfill() }
        wait(for: [settled], timeout: 2)
    }

    func assertFitted(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(cell.scrollView.zoomScale, 1, accuracy: 0.01, file: file, line: line)
        let frame = cell.imageView.convert(cell.imageView.bounds, to: cell.contentView)
        XCTAssertLessThanOrEqual(frame.width, cell.bounds.width + 1, file: file, line: line)
        XCTAssertLessThanOrEqual(frame.height, cell.bounds.height + 1, file: file, line: line)
        XCTAssertEqual(frame.midX, cell.bounds.midX, accuracy: 1, file: file, line: line)
        XCTAssertEqual(frame.midY, cell.bounds.midY, accuracy: 1, file: file, line: line)
    }

    func testDoubleTapThenPinchBackToFit() {
        let baseSize = cell.imageView.bounds.size
        doubleTap()
        XCTAssertGreaterThan(cell.scrollView.zoomScale, 1)
        XCTAssertEqual(cell.imageView.bounds.size, baseSize)
        // Drive the same scale/delegate path as UIScrollView's pinch recognizer.
        cell.scrollView.setZoomScale(1, animated: false)
        cell.scrollViewDidEndZooming(cell.scrollView, with: cell.imageView.superview, atScale: 1)
        assertFitted()
        XCTAssertTrue(cell.canBeginDismissInteraction)
    }

    func testPinchThenDoubleTapBackToFitAndRepeat() {
        cell.scrollView.setZoomScale(2, animated: false)
        doubleTap()
        assertFitted()
        doubleTap()
        XCTAssertGreaterThan(cell.scrollView.zoomScale, 1)
        XCTAssertFalse(cell.canBeginDismissInteraction)
        doubleTap()
        assertFitted()
    }

    func testDefaultAndConfiguredZoomRespectMaximum() {
        for size in [CGSize(width: 400, height: 600), CGSize(width: 100, height: 2000), CGSize(width: 2000, height: 100)] {
            setImage(size)
            cell.scrollView.maximumZoomScale = 2
            doubleTap()
            XCTAssertGreaterThan(cell.scrollView.zoomScale, 1)
            XCTAssertLessThanOrEqual(cell.scrollView.zoomScale, 2.01)
            doubleTap()
            assertFitted()
        }
        cell.doubleTapZoomScale = 8
        doubleTap()
        XCTAssertEqual(cell.scrollView.zoomScale, 2, accuracy: 0.01)
        doubleTap()
        assertFitted()
    }

    func testLayoutRotationAndReuseAfterDoubleTap() {
        doubleTap()
        let scale = cell.scrollView.zoomScale
        let frame = cell.imageView.superview!.frame
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        XCTAssertEqual(cell.scrollView.zoomScale, scale)
        XCTAssertEqual(cell.imageView.superview!.frame, frame)
        cell.prepareForSizeTransition()
        cell.applySizeTransition(to: CGSize(width: 844, height: 390))
        cell.frame.size = CGSize(width: 844, height: 390)
        cell.finishSizeTransition()
        assertFitted()
        doubleTap()
        cell.prepareForReuse()
        setImage(CGSize(width: 600, height: 400))
        assertFitted()
    }
}
