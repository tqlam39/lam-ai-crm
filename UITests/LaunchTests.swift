import XCTest

final class LaunchTests: XCTestCase {
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
}
