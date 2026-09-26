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

    func testZoomVetoAndDismissCompletionRestoreThumbnail() {
        let photos = app.collectionViews["lifecyclePhotos"]
        photos.doubleTap()
        waitFor("zoom=2.00")
        photos.swipeDown()
        waitFor("dragCount=0")
        capture("zoom-veto")
        photos.doubleTap()
        waitFor("zoom=1.00")
        photos.swipeDown()
        waitFor("closed=1;restored=1", id: "lifecycleRoot")
        capture("dismiss-complete-thumbnail-restored")
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
