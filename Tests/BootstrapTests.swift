import XCTest
@testable import LamAICRM

final class BootstrapTests: XCTestCase {
    func testVietnameseApplicationBundle() {
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.tqlam39.lamaicrm.ios")
    }
}
