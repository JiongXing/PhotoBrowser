import XCTest

final class RotationUITests: XCTestCase {
    let app = XCUIApplication()
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }
    override func tearDownWithError() throws {
        app.terminate()
        XCUIDevice.shared.orientation = .portrait
    }
    func launch(_ arguments: [String] = []) {
        app.launchArguments = ["ui-rotation"] + arguments
        app.launch()
        XCTAssertTrue(app.staticTexts["status"].waitForExistence(timeout: 10))
    }
    func waitFor(_ text: String, timeout: TimeInterval = 6, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: app.staticTexts["status"])
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, app.staticTexts["status"].label, file: file, line: line)
    }
    func checkPage(_ page: Int, landscape: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
        waitFor("landscape=\(landscape ? 1 : 0);transition=0", file: file, line: line)
        waitFor("page=\(page);visible=\(page);aligned=1", file: file, line: line)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "page-\(page)-\(landscape ? "landscape" : "portrait")"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testRotationDuringReloadAndNavigation() {
        launch()
        app.buttons["Reload"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        checkPage(1)
        waitFor("count=2")
        XCUIDevice.shared.orientation = .portrait
        checkPage(1, landscape: false)
        app.terminate()
        launch()
        app.buttons["Jump"].tap()
        XCUIDevice.shared.orientation = .landscapeRight
        checkPage(1)
    }
    func testDistantAnimatedNavigation() {
        launch(["nonloop"])
        app.buttons["Far"].tap()
        checkPage(4)
    }
    func testLoopBoundaryAndDeceleration() {
        launch(["last"])
        app.buttons["Drag"].tap()
        let photos = app.collectionViews["photos"]
        let start = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        let end = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
        waitFor("trigger=decelerating")
        waitFor("phase=decelerating")
        waitFor("preserved=0")
        checkPage(0)
    }
    func testRotationWhileFingerIsDragging() {
        launch(["dragging"])
        app.buttons["Drag"].tap()
        let photos = app.collectionViews["photos"]
        let start = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let end = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.5)
        waitFor("phase=dragging")
        let preserved = app.staticTexts["status"].label.components(separatedBy: "preserved=")[1].components(separatedBy: ";")[0]
        checkPage(Int(preserved)!)
    }
    func testVerticalPagingAndDoubleTap() {
        launch(["vertical", "nonloop"])
        app.collectionViews["photos"].swipeUp()
        waitFor("page=1;visible=1")
        app.collectionViews["photos"].doubleTap()
        waitFor("fit=0")
        XCUIDevice.shared.orientation = .landscapeLeft
        checkPage(1)
        waitFor("fit=1")
        app.collectionViews["photos"].doubleTap()
        waitFor("fit=0")
    }
    func testPinchAndAutoplayRecoverAfterRotation() {
        launch()
        app.collectionViews["photos"].pinch(withScale: 2, velocity: 1)
        let zoomed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "NOT (label CONTAINS 'zoom=1.00')"), object: app.staticTexts["status"])
        XCTAssertEqual(XCTWaiter.wait(for: [zoomed], timeout: 3), .completed, app.staticTexts["status"].label)
        XCUIDevice.shared.orientation = .landscapeRight
        checkPage(0)
        waitFor("zoom=1.00")
        assertAutoplayRecovers()
    }
    func testDoubleTapZoomAndAutoplayRecoverAfterRotation() {
        launch(["fixedzoom"])
        app.collectionViews["photos"].doubleTap()
        waitFor("zoom=2.00")
        XCUIDevice.shared.orientation = .landscapeLeft
        checkPage(0)
        waitFor("zoom=1.00")
        assertAutoplayRecovers()
    }
    func assertAutoplayRecovers() {
        app.buttons["Auto"].tap()
        XCUIDevice.shared.orientation = .portrait
        waitFor("landscape=0;transition=0")
        let initial = app.staticTexts["status"].label.components(separatedBy: ";")[0]
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "NOT (label BEGINSWITH %@)", initial + ";"), object: app.staticTexts["status"])
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
        app.buttons["Auto"].tap()
    }
}
