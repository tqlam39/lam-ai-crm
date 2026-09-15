import XCTest

final class LaunchTests: XCTestCase {
    func testCustomerCanBeSavedAndProfileReopened() {
        let app = XCUIApplication();app.launch()
        XCTAssertTrue(app.buttons["tab-Khách"].waitForExistence(timeout:45));app.buttons["tab-Khách"].tap()
        app.buttons["add-customer"].tap()
        let name = app.textFields["customer-name"]
        XCTAssertTrue(name.waitForExistence(timeout:10));name.tap();name.typeText("Khach iOS")
        app.buttons["save-customer"].tap()
        XCTAssertTrue(app.navigationBars["Khách hàng"].waitForExistence(timeout:10))
        app.terminate();app.launch()
        XCTAssertTrue(app.buttons["tab-Khách"].waitForExistence(timeout:45));app.buttons["tab-Khách"].tap()
        let customer = app.buttons.matching(NSPredicate(format:"label CONTAINS %@","Khach iOS")).firstMatch
        XCTAssertTrue(customer.waitForExistence(timeout:10),app.debugDescription);customer.tap()
        XCTAssertTrue(app.navigationBars["Khach iOS"].waitForExistence(timeout:10))
    }
    func testNativeScreenActuallyAppears() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["LẮM AI CRM"].waitForExistence(timeout: 45), "Giao diện gốc phải hiện, không chỉ launch process.")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Giao diện native đã hiển thị"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    func testBottomNavigationAndQuickAdd() {
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.buttons["tab-BĐS"].waitForExistence(timeout:45))
        app.buttons["tab-BĐS"].tap()
        XCTAssertTrue(app.navigationBars["Quỹ bất động sản"].exists)
        app.buttons["tab-Khách"].tap()
        XCTAssertTrue(app.navigationBars["Khách hàng"].exists)
        app.buttons["quickAdd"].tap()
        XCTAssertTrue(app.buttons["BĐS thủ công"].waitForExistence(timeout:5))
        app.buttons["Đóng"].tap()
        app.buttons["tab-AI"].tap()
        XCTAssertTrue(app.navigationBars["AI Copilot"].exists)
    }
    func testPropertyDraftPersistsAcrossLaunch() {
        let app = XCUIApplication();app.launch()
        XCTAssertTrue(app.buttons["quickAdd"].waitForExistence(timeout:45))
        app.buttons["quickAdd"].tap();app.buttons["BĐS thủ công"].tap()
        let title = app.textFields["property-title"]
        XCTAssertTrue(title.waitForExistence(timeout:10));title.tap();title.typeText("Ban nhap iOS")
        app.buttons["toolbar-save-draft"].tap()
        XCTAssertTrue(app.navigationBars["Quỹ bất động sản"].waitForExistence(timeout:10))
        app.terminate();app.launch()
        XCTAssertTrue(app.buttons["tab-BĐS"].waitForExistence(timeout:45));app.buttons["tab-BĐS"].tap()
        app.segmentedControls["property-scope"].buttons["Bản nháp"].tap()
        let draft = app.buttons.matching(NSPredicate(format:"label CONTAINS %@", "Ban nhap iOS")).firstMatch
        XCTAssertTrue(draft.waitForExistence(timeout:10), app.debugDescription)
        draft.tap()
        XCTAssertTrue(app.textFields["property-title"].waitForExistence(timeout:10))
        XCTAssertEqual(app.textFields["property-title"].value as? String,"Ban nhap iOS")
    }
}
