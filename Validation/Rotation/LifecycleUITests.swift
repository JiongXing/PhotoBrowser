import XCTest

final class LifecycleUITests: XCTestCase {
    let app = XCUIApplication()
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["ui-lifecycle"]
        app.launch()
        app.buttons["Open"].tap()
        XCTAssertTrue(app.staticTexts["lifecycleStatus"].waitForExistence(timeout: 5))
    }
    override func tearDownWithError() throws { app.terminate() }

    func waitFor(_ value: String, id: String = "lifecycleStatus") {
        let element = app.staticTexts[id]
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", value), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 8), .completed, element.label)
    }
    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testDismissCancelPausesAutoplayThenResumes() {
        app.buttons["Auto"].tap()
        let photos = app.collectionViews["lifecyclePhotos"]
        let start = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        let end = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.56))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 2)
        waitFor("dragCount=1;dragging=0;moved=0")
        waitFor("scroll=1")
        waitFor("resumed=1")
        capture("dismiss-cancel-autoplay-resumed")
    }

    func testZoomedMiddleScrollThenFitDismissRestoresThumbnail() {
        let photos = app.collectionViews["lifecyclePhotos"]
        photos.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
        waitFor("zoom=2.00")
        capture("zoomed-landscape-before-scroll")
        waitFor("top=0")
        photos.swipeDown()
        waitFor("dragCount=0")
        capture("zoomed-middle-scroll")
        photos.doubleTap()
        waitFor("fit=1")
        photos.swipeDown()
        waitFor("closed=1;restored=1", id: "lifecycleRoot")
        capture("dismiss-complete-thumbnail-restored")
    }

    func openLongImage(fixedZoom: Bool = false) {
        app.terminate()
        app.launchArguments = ["ui-lifecycle", "long-image"] + (fixedZoom ? ["fixedzoom"] : [])
        app.launch()
        app.buttons["Open"].tap()
        waitFor("fit=1")
    }

    func drag(_ from: CGFloat, to: CGFloat, hold: TimeInterval = 1) {
        let photos = app.collectionViews["lifecyclePhotos"]
        let start = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: from))
        let end = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: to))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: hold)
    }

    func testLongImageFillScrollToTopThenNewPullDismisses() {
        openLongImage()
        let photos = app.collectionViews["lifecyclePhotos"]
        photos.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18)).doubleTap()
        waitFor("zoom=1.00;fit=0;widthFill=1;top=0")
        capture("long-image-width-filled")
        drag(0.25, to: 0.8)
        waitFor("top=1")
        waitFor("dragCount=0")
        capture("long-image-at-top-without-dismiss")
        drag(0.3, to: 0.7)
        waitFor("closed=1;restored=1", id: "lifecycleRoot")
        capture("long-image-new-pull-dismissed")
    }

    func testLongImageZoomedTopCancelPreservesScaleThenDismisses() {
        openLongImage(fixedZoom: true)
        let photos = app.collectionViews["lifecyclePhotos"]
        photos.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).doubleTap()
        waitFor("zoom=2.00")
        waitFor("top=0")
        drag(0.2, to: 0.85)
        waitFor("top=1")
        waitFor("dragCount=0")
        drag(0.4, to: 0.48)
        waitFor("dragCount=1;dragging=0")
        waitFor("zoom=2.00;fit=0;widthFill=0;top=1")
        waitFor("scroll=1")
        capture("long-image-2x-cancel-preserved")
        drag(0.3, to: 0.7)
        waitFor("closed=1;restored=1", id: "lifecycleRoot")
    }

    func testLongImagePinchDoesNotBeginDismiss() {
        openLongImage()
        let photos = app.collectionViews["lifecyclePhotos"]
        photos.pinch(withScale: 3, velocity: 1)
        waitFor("fit=0")
        waitFor("dragCount=0")
        capture("long-image-pinch-without-dismiss")
    }

    func openNavigationContainer() {
        app.terminate()
        app.launchArguments = ["ui-lifecycle", "navigation-container"]
        app.launch()
        app.buttons["Open"].tap()
        waitFor("page=0")
    }

    func testNonanimatedNavigationContainerDismissRestoresThumbnail() {
        openNavigationContainer()
        app.buttons["Close"].tap()
        waitFor("closed=1;restored=1", id: "lifecycleRoot")
        capture("navigation-nonanimated-dismiss-restored")
    }

    func testAnimatedNavigationContainerDismissRestoresThumbnail() {
        openNavigationContainer()
        app.buttons["Animated"].tap()
        waitFor("closed=1;restored=1", id: "lifecycleRoot")
        capture("navigation-animated-dismiss-restored")
    }

    func testNavigationContainerTemporaryCoverThenDismiss() {
        openNavigationContainer()
        app.buttons["Cover"].tap()
        waitFor("hidden=1", id: "coverStatus")
        capture("navigation-covered-thumbnail-hidden")
        app.buttons["Return"].tap()
        waitFor("page=0")
        app.collectionViews["lifecyclePhotos"].swipeLeft()
        waitFor("page=1")
        capture("navigation-returned-and-paged")
        app.buttons["Close"].tap()
        waitFor("closed=1;restored=1", id: "lifecycleRoot")
        capture("navigation-cover-return-dismiss-restored")
    }
}
