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
}
