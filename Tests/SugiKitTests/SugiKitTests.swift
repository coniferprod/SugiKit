import XCTest
@testable import SugiKit

final class SugiKitTests: XCTestCase {
    func testNoteName() {
        XCTAssertEqual(noteName(for: 60), "C4")
    }

    func testKeyNumber() {
        XCTAssertEqual(keyNumber(for: "C4"), 60)
    }

    func testEmptyBankCreation() {
        let bank = Bank()
        XCTAssertEqual(bank.singles.count, Bank.singlePatchCount)
        XCTAssertEqual(bank.multis.count, Bank.multiPatchCount)
        XCTAssertEqual(bank.effects.count, Bank.effectPatchCount)
    }
    
    func testBitField() {
        let b: Byte = 0b0011_0000
        let field = b.bitField(start: 3, end: 6)  // bits 3, 4, and 5
        XCTAssertEqual(field, 0b0000_0110)
    }
}
