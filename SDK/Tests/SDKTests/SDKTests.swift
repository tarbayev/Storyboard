import XCTest
@testable import SDK

final class SDKTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SDK().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
