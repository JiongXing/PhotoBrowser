import XCTest
@testable import RotationHost

// A real UIKit collection view with controllable transition callback timing.
// This verifies state ordering; system rotation is covered by RotationUITests.
@MainActor
final class RotationTests: XCTestCase {
    var window: UIWindow!
    var browser: JXPhotoBrowserViewController!
    var data: RotationData!

    override func setUp() {
        super.setUp()
        data = RotationData()
        browser = JXPhotoBrowserViewController()
        browser.isLoopingEnabled = false
        browser.initialIndex = 4
        browser.delegate = data
        browser.transitionType = .zoom
        window = UIWindow(windowScene: UIApplication.shared.connectedScenes.first as! UIWindowScene)
        window.rootViewController = browser
        window.makeKeyAndVisible()
        browser.view.layoutIfNeeded()
        browser.collectionView.layoutIfNeeded()
        browser.endAppearanceTransition()
        XCTAssertEqual(browser.pageIndex, 4)
    }

    override func tearDown() {
        browser.isAutoPlayEnabled = false
        window.isHidden = true
        window.rootViewController = nil
        window = nil
        browser = nil
        data = nil
        super.tearDown()
    }

    func begin() -> ControlledTransition {
        let coordinator = ControlledTransition()
        browser.viewWillTransition(to: CGSize(width: 844, height: 390), with: coordinator)
        return coordinator
    }

    func animate(_ coordinator: ControlledTransition) {
        browser.view.frame.size = CGSize(width: 844, height: 390)
        browser.view.setNeedsLayout()
        browser.view.layoutIfNeeded()
        coordinator.animation?(coordinator)
        browser.collectionView.layoutIfNeeded()
    }

    func assertPage(_ expected: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(browser.pageIndex, expected, file: file, line: line)
        if data.count > 0 {
            let cv = browser.collectionView
            let position = browser.scrollDirection == .horizontal ? cv.contentOffset.x / cv.bounds.width : cv.contentOffset.y / cv.bounds.height
            XCTAssertEqual(position, position.rounded(), accuracy: 0.01, file: file, line: line)
            XCTAssertEqual(Int(position.rounded()) % data.count, expected, file: file, line: line)
        }
        XCTAssertTrue(data.invalidHiddenIndexes.isEmpty, "Out of range callbacks: \(data.invalidHiddenIndexes)", file: file, line: line)
    }

    func testReloadSmallerDuringTransition() {
        let c = begin()
        animate(c)
        data.count = 2
        browser.reloadData()
        c.completion?(c)
        assertPage(1)
    }

    func testReloadEmptyDuringTransition() {
        let c = begin()
        animate(c)
        data.count = 0
        browser.reloadData()
        c.completion?(c)
        assertPage(0)
        XCTAssertEqual(browser.collectionView.numberOfItems(inSection: 0), 0)
    }

    func testNavigationDuringTransition() {
        let c = begin()
        animate(c)
        browser.scrollToPage(at: 1, animated: false)
        c.completion?(c)
        assertPage(1)
    }
    func testLatestSelectionBeforeAnimation() {
        let c = begin()
        data.count = 2
        browser.reloadData()
        browser.scrollToPage(at: 0, animated: false)
        animate(c)
        c.completion?(c)
        assertPage(0)
    }

    func testAnimatedNavigationDuringTransition() {
        let c = begin()
        animate(c)
        browser.scrollToPage(at: 1, animated: true)
        c.completion?(c)
        assertPage(1)
    }

    func testInvalidNavigationDoesNotReplaceSelection() {
        let c = begin()
        browser.scrollToPage(at: 99, animated: false)
        animate(c)
        c.completion?(c)
        assertPage(4)
    }

    func testIncomingCellPreparedBeforeDisplayAndUnlockedAfterCompletion() throws {
        browser.register(ObservedCell.self, forReuseIdentifier: "observed")
        data.reuseIdentifier = "observed"
        browser.reloadData()
        browser.scrollToPage(at: 0, animated: false)
        browser.scrollToPage(at: 4, animated: true)
        let c = begin()
        data.requirePreparedCells = true
        animate(c)
        XCTAssertTrue(data.unpreparedIndexes.isEmpty)
        XCTAssertTrue(data.observedCells.values.allSatisfy { $0.unpreparedLayouts == 0 })
        let cell = try XCTUnwrap(browser.visibleZoomImageCell() as? ObservedCell)
        XCTAssertGreaterThan(cell.prepareCount, 0)
        XCTAssertGreaterThan(cell.applyCount, 0)
        c.completion?(c)
        XCTAssertGreaterThan(cell.finishCount, 0)
        assertPage(4)
        cell.imageView.image = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 800)).image { _ in }
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        XCTAssertEqual(cell.imageView.bounds.width / cell.imageView.bounds.height, 0.25, accuracy: 0.001)
    }

    func testCellReuseAndZoomCallbacksCannotKeepOldGeometry() {
        let cell = JXZoomImageCell(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        cell.imageView.image = data.image
        cell.layoutIfNeeded()
        cell.scrollView.setZoomScale(2, animated: false)
        cell.prepareForSizeTransition()
        cell.applySizeTransition(to: CGSize(width: 844, height: 390))
        let transitioningFrame = cell.imageView.superview!.frame
        cell.scrollViewDidEndZooming(cell.scrollView, with: nil, atScale: 1)
        cell.adjustImageViewFrame()
        cell.layoutSubviews()
        XCTAssertEqual(cell.imageView.superview!.frame, transitioningFrame)
        cell.frame.size = CGSize(width: 844, height: 390)
        cell.finishSizeTransition()
        XCTAssertEqual(cell.scrollView.zoomScale, 1)
        XCTAssertEqual(cell.imageView.bounds.size, CGSize(width: 585, height: 390))
        cell.prepareForSizeTransition()
        cell.prepareForReuse()
        cell.imageView.image = data.image
        cell.frame.size = CGSize(width: 390, height: 844)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        XCTAssertEqual(cell.imageView.bounds.size, CGSize(width: 390, height: 260))
    }

    func testDirectionsSpacingAndLoopBoundary() {
        for direction in [JXPhotoBrowserScrollDirection.horizontal, .vertical] {
            for looping in [false, true] {
                browser.scrollDirection = direction
                browser.itemSpacing = 20
                browser.isLoopingEnabled = looping
                browser.scrollToPage(at: 4, animated: false)
                let cv = browser.collectionView
                browser.scrollViewWillBeginDragging(cv)
                // Just over half of the next page, before the end-drag/deceleration callback.
                let virtual = looping ? 29.7 : 2.7
                cv.contentOffset = direction == .horizontal
                    ? CGPoint(x: cv.bounds.width * virtual, y: 0)
                    : CGPoint(x: 0, y: cv.bounds.height * virtual)
                let c = begin()
                animate(c)
                c.completion?(c)
                assertPage(looping ? 0 : 3)
            }
        }
    }

    func testAutoplayStaysPausedAfterReloadAndResumes() {
        browser.isLoopingEnabled = true
        browser.scrollToPage(at: 0, animated: false)
        browser.autoPlayInterval = 0.5
        browser.isAutoPlayEnabled = true
        let c = begin()
        animate(c)
        browser.reloadData()
        browser.scrollToPage(at: 1, animated: false)
        let before = browser.collectionView.contentOffset
        let paused = expectation(description: "autoplay paused throughout resize")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            XCTAssertEqual(self.browser.collectionView.contentOffset, before)
            XCTAssertEqual(self.browser.pageIndex, 1)
            c.completion?(c)
            paused.fulfill()
        }
        wait(for: [paused], timeout: 2)
        let resumed = expectation(description: "autoplay resumed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            XCTAssertNotEqual(self.browser.collectionView.contentOffset, before)
            self.browser.isAutoPlayEnabled = false
            resumed.fulfill()
        }
        wait(for: [resumed], timeout: 3)
    }

    func testOldCompletionCannotFinishNewTransition() {
        let first = begin()
        animate(first)
        let second = begin()
        animate(second)
        first.completion?(first)
        XCTAssertFalse(browser.collectionView.isScrollEnabled)
        browser.scrollToPage(at: 1, animated: false)
        second.completion?(second)
        assertPage(1)
        XCTAssertTrue(browser.collectionView.isScrollEnabled)
    }

    func testDefaultOrientationPolicyUnchanged() {
        XCTAssertFalse(browser.shouldAutorotate)
        XCTAssertEqual(browser.supportedInterfaceOrientations, .portrait)
    }

}

@MainActor
final class RotationData: NSObject, JXPhotoBrowserDelegate {
    var count = 5
    var reuseIdentifier = JXZoomImageCell.reuseIdentifier
    var requirePreparedCells = false
    var unpreparedIndexes: [Int] = []
    var observedCells: [ObjectIdentifier: ObservedCell] = [:]
    var invalidHiddenIndexes: [Int] = []
    let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400)).image { context in
        UIColor.systemBlue.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
    }
    func numberOfItems(in browser: JXPhotoBrowserViewController) -> Int { count }
    func photoBrowser(_ browser: JXPhotoBrowserViewController, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let cell = browser.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! JXZoomImageCell
        cell.imageView.image = image
        if let cell = cell as? ObservedCell {
            cell.expectsPreparedLayout = requirePreparedCells
            observedCells[ObjectIdentifier(cell)] = cell
        }
        return cell
    }
    func photoBrowser(_ browser: JXPhotoBrowserViewController, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int) {
        if requirePreparedCells, let cell = cell as? ObservedCell, !cell.prepared { unpreparedIndexes.append(index) }
    }
    func photoBrowser(_ browser: JXPhotoBrowserViewController, setThumbnailHidden hidden: Bool, at index: Int) {
        if !(0..<count).contains(index) { invalidHiddenIndexes.append(index) }
    }
}

final class ControlledTransition: NSObject, UIViewControllerTransitionCoordinator {
    var animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?
    var completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)?
    var isAnimated: Bool { true }
    var presentationStyle: UIModalPresentationStyle { .none }
    var initiallyInteractive: Bool { false }
    var isInterruptible: Bool { true }
    var isInteractive: Bool { false }
    var isCancelled: Bool { false }
    var transitionDuration: TimeInterval { 0.3 }
    var percentComplete: CGFloat { 1 }
    var completionVelocity: CGFloat { 1 }
    var completionCurve: UIView.AnimationCurve { .easeInOut }
    var containerView: UIView { UIView() }
    var targetTransform: CGAffineTransform { .identity }
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? { nil }
    func view(forKey key: UITransitionContextViewKey) -> UIView? { nil }
    func animate(alongsideTransition animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?, completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool {
        self.animation = animation
        self.completion = completion
        return true
    }
    func animateAlongsideTransition(in view: UIView?, animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?, completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool { true }
    func notifyWhenInteractionEnds(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}
    func notifyWhenInteractionChanges(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}
}

final class ObservedCell: JXZoomImageCell {
    var prepared = false
    var prepareCount = 0
    var applyCount = 0
    var finishCount = 0
    var expectsPreparedLayout = false
    var unpreparedLayouts = 0
    override func layoutSubviews() {
        if expectsPreparedLayout && !prepared { unpreparedLayouts += 1 }
        super.layoutSubviews()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        prepared = false
    }
    override func prepareForSizeTransition() {
        super.prepareForSizeTransition()
        prepared = true
        prepareCount += 1
    }
    override func applySizeTransition(to size: CGSize) {
        super.applySizeTransition(to: size)
        applyCount += 1
    }
    override func finishSizeTransition() {
        super.finishSizeTransition()
        prepared = false
        expectsPreparedLayout = false
        finishCount += 1
    }
}
