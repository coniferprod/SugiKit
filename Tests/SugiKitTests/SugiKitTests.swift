import XCTest
@testable import SugiKit

final class SugiKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SugiKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
