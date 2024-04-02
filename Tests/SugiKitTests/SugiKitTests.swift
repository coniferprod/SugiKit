import XCTest
@testable import SugiKit
import ByteKit
import SyxPack

final class SugiKitTests: XCTestCase {
    func testEmptyBankCreation() {
        let bank = Bank()
        XCTAssertEqual(bank.singles.count, Bank.singlePatchCount)
        XCTAssertEqual(bank.multis.count, Bank.multiPatchCount)
        XCTAssertEqual(bank.effects.count, Bank.effectPatchCount)
    }
    
    func testBitField() {
        let b: Byte = 0b0011_0000
        let field = b.extractBits(start: 3, length: 3)  // bits 3, 4, and 5
        XCTAssertEqual(field, 0b0000_0110)
    }
    
    func testPatchNameFromStringLiteral() {
        let name = PatchName("MeloVox1")  // from string literal
        XCTAssertEqual(name.value, "MeloVox1  ")  // should be padded to length 10
    }
}
