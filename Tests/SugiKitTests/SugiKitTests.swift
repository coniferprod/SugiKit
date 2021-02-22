import XCTest
@testable import SugiKit

final class SugiKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SugiKit().text, "Hello, World!")
    }

    func testDecodeWaveNumber() {
        let note = DrumNote()

        XCTAssertEqual(note.decodeWaveNumber(msb: 0x01, lsb: 0x7f), 128)
        
    }
    
    func testEncodeWaveNumber() {
        let note = DrumNote()

        let (highByte, lowByte) = note.encodeWaveNumber(waveNumber: 128)
        XCTAssertEqual(highByte, 0x01)
        XCTAssertEqual(lowByte, 0x7f)

    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
