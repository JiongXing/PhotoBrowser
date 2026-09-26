import XCTest
@testable import RotationHost

@MainActor
final class LifecycleTests: XCTestCase {
    var window: UIWindow!
    var root: UIViewController!
    var browser: JXPhotoBrowserViewController!
    var data: LifecycleData!

    override func setUp() {
        super.setUp()
        data = LifecycleData()
        root = UIViewController()
        window = UIWindow(windowScene: UIApplication.shared.connectedScenes.first as! UIWindowScene)
        window.rootViewController = root
        window.makeKeyAndVisible()
        browser = JXPhotoBrowserViewController()
        browser.delegate = data
        browser.isLoopingEnabled = false
        browser.transitionType = .zoom
        browser.initialIndex = 4
        root.addChild(browser)
        root.view.addSubview(browser.view)
        browser.view.frame = root.view.bounds
        browser.didMove(toParent: root)
        browser.view.layoutIfNeeded()
        browser.collectionView.layoutIfNeeded()
        drain(0.1)
        XCTAssertEqual(browser.pageIndex, 4)
        XCTAssertTrue(data.thumbnails[4].isHidden)
    }

    override func tearDown() {
        browser.isAutoPlayEnabled = false
        browser.restoreThumbnail()
        window.isHidden = true
        window.rootViewController = nil
        browser = nil
        root = nil
        window = nil
        data = nil
        super.tearDown()
    }

    func drain(_ duration: TimeInterval) {
        let e = expectation(description: "UIKit callbacks")
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { e.fulfill() }
        wait(for: [e], timeout: duration + 3)
    }

    func pan(_ state: UIGestureRecognizer.State, translation: CGPoint = .zero) {
        if state == .began { browser.collectionView.layoutIfNeeded() }
        let pan = LifecyclePan()
        pan.state = state
        pan.setTranslation(translation, in: browser.view)
        browser.perform(NSSelectorFromString("handlePanGesture:"), with: pan)
    }

    func enableAutoplay() {
        browser.scrollToPage(at: 0, animated: false)
        browser.autoPlayInterval = 0.5
        browser.isAutoPlayEnabled = true
    }

    func presentModally() {
        browser.willMove(toParent: nil)
        browser.view.removeFromSuperview()
        browser.removeFromParent()
        browser.modalPresentationStyle = .overFullScreen
        browser.transitioningDelegate = browser
        root.present(browser, animated: false)
        drain(0.1)
        XCTAssertTrue(data.thumbnails[4].isHidden)
    }

    func testShrinkAndEmptyRestoreOriginalWithoutInvalidCallbacks() {
        for count in [2, 0] {
            let old = data.thumbnails[browser.pageIndex]
            data.thumbnails = Array(data.thumbnails.prefix(count))
            browser.reloadData()
            XCTAssertFalse(old.isHidden)
            XCTAssertEqual(browser.pageIndex, max(0, count - 1))
            XCTAssertTrue(data.invalidIndexes.isEmpty, "\(data.invalidIndexes)")
        }
    }

    func testReplacementRestoresOldViewAndOriginalVisibility() {
        let old = data.thumbnails[4]
        data.thumbnails[4] = UIImageView()
        browser.reloadData()
        XCTAssertFalse(old.isHidden)
        XCTAssertTrue(data.thumbnails[4].isHidden)
        browser.restoreThumbnail()
        data.thumbnails[4].isHidden = true
        browser.hideCurrentThumbnail()
        browser.restoreThumbnail()
        XCTAssertTrue(data.thumbnails[4].isHidden)
    }

    func testCustomRestorationCapturesOriginalObject() {
        browser.restoreThumbnail()
        data.customVisibility = true
        let original = data.thumbnails[4]
        original.alpha = 0.7
        browser.hideCurrentThumbnail()
        XCTAssertEqual(original.alpha, 0)
        data.thumbnails = []
        browser.reloadData()
        XCTAssertEqual(original.alpha, 0.7, accuracy: 0.001)
        XCTAssertEqual(data.restorationCount, 1)
        XCTAssertTrue(data.invalidIndexes.isEmpty)
    }

    func testRehidingReusedThumbnailPreservesOriginalState() {
        let thumbnail = data.thumbnails[4]
        thumbnail.isHidden = false
        browser.hideCurrentThumbnail()
        XCTAssertTrue(thumbnail.isHidden)
        browser.hideCurrentThumbnail()
        browser.restoreThumbnail()
        XCTAssertFalse(thumbnail.isHidden)
    }

    func testNonanimatedDismissRestoresThumbnail() {
        presentModally()
        browser.dismiss(animated: false)
        drain(0.1)
        XCTAssertNil(root.presentedViewController)
        XCTAssertFalse(data.thumbnails[4].isHidden)
    }

    func testAnimatedDismissRestoresThumbnail() {
        presentModally()
        browser.dismissSelf()
        drain(0.6)
        XCTAssertNil(root.presentedViewController)
        XCTAssertFalse(data.thumbnails[4].isHidden)
    }

    func testTemporaryFullScreenCoverKeepsRestoration() {
        presentModally()
        let cover = UIViewController()
        cover.modalPresentationStyle = .fullScreen
        browser.present(cover, animated: false)
        drain(0.1)
        XCTAssertTrue(data.thumbnails[4].isHidden)
        cover.dismiss(animated: false)
        drain(0.1)
        XCTAssertTrue(data.thumbnails[4].isHidden)
        browser.dismiss(animated: false)
        drain(0.1)
        XCTAssertFalse(data.thumbnails[4].isHidden)
    }

    func testAutoplayPausesThroughPanAndReboundThenResumes() {
        enableAutoplay()
        pan(.began)
        XCTAssertFalse(browser.collectionView.isScrollEnabled)
        let before = browser.collectionView.contentOffset
        pan(.changed, translation: CGPoint(x: 0, y: 80))
        drain(0.8)
        XCTAssertEqual(browser.collectionView.contentOffset, before)
        XCTAssertEqual(browser.pageIndex, 0)
        pan(.cancelled)
        drain(0.1)
        XCTAssertEqual(browser.collectionView.contentOffset, before)
        drain(1.0)
        XCTAssertGreaterThan(browser.pageIndex, 0)
        XCTAssertTrue(browser.collectionView.isScrollEnabled)
    }

    func testInterruptedReboundCannotUnlockSizeTransition() {
        enableAutoplay()
        pan(.began)
        let cell = browser.visibleZoomImageCell()!
        pan(.changed, translation: CGPoint(x: 0, y: 100))
        pan(.cancelled)
        let transition = ControlledTransition()
        browser.viewWillTransition(to: CGSize(width: 844, height: 390), with: transition)
        drain(0.35)
        XCTAssertFalse(browser.collectionView.isScrollEnabled)
        XCTAssertEqual(cell.imageView.transform, .identity)
        XCTAssertEqual(browser.pageIndex, 0)
        transition.completion?(transition)
        XCTAssertTrue(browser.collectionView.isScrollEnabled)
    }

    func testReloadAndNavigationEndOldInteraction() {
        for reload in [true, false] {
            browser.scrollToPage(at: 0, animated: false)
            pan(.began)
            let cell = browser.visibleZoomImageCell()!
            pan(.changed, translation: CGPoint(x: 0, y: 80))
            if reload { browser.reloadData() } else { browser.scrollToPage(at: 2, animated: false) }
            XCTAssertEqual(cell.imageView.transform, .identity)
            XCTAssertTrue(cell.scrollView.isScrollEnabled)
            XCTAssertTrue(browser.collectionView.isScrollEnabled)
            XCTAssertEqual(browser.pageIndex, reload ? 0 : 2)
        }
    }

    func testOldReboundCannotEndNewInteraction() {
        pan(.began)
        pan(.cancelled)
        browser.scrollToPage(at: 0, animated: false)
        pan(.began)
        drain(0.35)
        XCTAssertFalse(browser.collectionView.isScrollEnabled)
        XCTAssertFalse(browser.visibleZoomImageCell()!.scrollView.isScrollEnabled)
        pan(.cancelled)
        drain(0.35)
        XCTAssertTrue(browser.collectionView.isScrollEnabled)
    }

    func testDisappearingDoesNotRestartAutoplayAfterReset() {
        enableAutoplay()
        pan(.began)
        browser.beginAppearanceTransition(false, animated: false)
        browser.endAppearanceTransition()
        let before = browser.collectionView.contentOffset
        drain(0.9)
        XCTAssertEqual(browser.collectionView.contentOffset, before)
    }

    func testCustomCellCanRejectDismissWithoutSubclassingZoomCell() {
        browser.register(VetoCell.self, forReuseIdentifier: "veto")
        data.useVetoCell = true
        browser.reloadData()
        browser.collectionView.layoutIfNeeded()
        let cell = browser.visibleCell() as! VetoCell
        pan(.began)
        XCTAssertEqual(cell.interactionCount, 0)
        XCTAssertTrue(browser.collectionView.isScrollEnabled)
    }

    func testZoomCellRestoresOriginalConfiguration() {
        let cell = browser.visibleZoomImageCell()!
        cell.scrollView.isScrollEnabled = false
        cell.clipsToBounds = false
        cell.contentView.clipsToBounds = true
        cell.scrollView.clipsToBounds = false
        browser.collectionView.isScrollEnabled = false
        pan(.began)
        pan(.cancelled)
        drain(0.35)
        XCTAssertFalse(cell.scrollView.isScrollEnabled)
        XCTAssertFalse(cell.clipsToBounds)
        XCTAssertTrue(cell.contentView.clipsToBounds)
        XCTAssertFalse(cell.scrollView.clipsToBounds)
        XCTAssertFalse(browser.collectionView.isScrollEnabled)
        cell.scrollView.setZoomScale(2, animated: false)
        XCTAssertFalse(cell.canBeginDismissInteraction)
    }
}

final class LifecyclePan: UIPanGestureRecognizer {
    private var testState: UIGestureRecognizer.State = .possible
    override var state: UIGestureRecognizer.State {
        get { testState }
        set { testState = newValue }
    }
}

@MainActor
final class LifecycleData: NSObject, @preconcurrency JXPhotoBrowserDelegate {
    var thumbnails = (0..<5).map { _ in UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50)) }
    var invalidIndexes: [Int] = []
    var customVisibility = false
    var restorationCount = 0
    var useVetoCell = false
    let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400)).image { c in
        UIColor.blue.setFill()
        c.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
    }
    func numberOfItems(in browser: JXPhotoBrowserViewController) -> Int { thumbnails.count }
    func photoBrowser(_ browser: JXPhotoBrowserViewController, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        if useVetoCell { return browser.dequeueReusableCell(withReuseIdentifier: "veto", for: indexPath) }
        let cell = browser.dequeueReusableCell(withReuseIdentifier: JXZoomImageCell.reuseIdentifier, for: indexPath) as! JXZoomImageCell
        cell.imageView.image = image
        return cell
    }
    func photoBrowser(_ browser: JXPhotoBrowserViewController, thumbnailViewAt index: Int) -> UIView? {
        guard thumbnails.indices.contains(index) else { invalidIndexes.append(index); return nil }
        return thumbnails[index]
    }
    func photoBrowser(_ browser: JXPhotoBrowserViewController, setThumbnailHidden hidden: Bool, at index: Int) {
        guard thumbnails.indices.contains(index) else { invalidIndexes.append(index); return }
        if customVisibility { thumbnails[index].alpha = hidden ? 0 : 1 }
        else { thumbnails[index].isHidden = hidden }
    }
    func photoBrowser(_ browser: JXPhotoBrowserViewController, thumbnailRestorationAt index: Int) -> (() -> Void)? {
        guard customVisibility else { return nil }
        let view = thumbnails[index]
        let alpha = view.alpha
        return { [weak self, weak view] in
            view?.alpha = alpha
            self?.restorationCount += 1
        }
    }
}

final class VetoCell: UICollectionViewCell, JXPhotoBrowserCellProtocol {
    let imageView = UIImageView()
    var transitionImageView: UIImageView? { imageView }
    var canBeginDismissInteraction: Bool { false }
    var interactionCount = 0
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        contentView.addSubview(imageView)
    }
    required init?(coder: NSCoder) { fatalError() }
    func photoBrowserDismissInteractionDidChange(isInteracting: Bool) { interactionCount += 1 }
}
