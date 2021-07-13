import XCTest
@testable import SugiKit

// Test cases related to parsing System Exclusive files to get domain objects.
final class AbsorptionTests: XCTestCase {
    var bankData = ByteArray()
    
    override func setUp() {
        
        guard let bankURL = Bundle.module.url(forResource: "A401", withExtension: "SYX") else {
            XCTFail("Bank file not found in resources")
            return
        }
        
        guard let data = try? Data(contentsOf: bankURL) else {
            XCTFail("Unable to read bank data")
            return
        }
        
        let dataBytes = data.bytes
        print("Got \(dataBytes.count) bytes for bank")

        self.bankData = dataBytes.slice(from: SystemExclusiveHeader.dataSize, length: dataBytes.count - (SystemExclusiveHeader.dataSize + 1))
        
        print("Bank data = \(self.bankData.count) bytes")
    }

    func testParsingBank() {
        let bank = Bank(bytes: self.bankData)
        XCTAssertEqual(bank.singles.count, Bank.singlePatchCount)
        XCTAssertEqual(bank.multis.count, Bank.multiPatchCount)
        XCTAssertEqual(bank.effects.count, Bank.effectPatchCount)
    }

    func testParsingSingles() {
        let bank = Bank(bytes: self.bankData)
        let firstSingle = bank.singles[0]
        XCTAssertEqual(firstSingle.name, "Melo Vox 1")
    }

    func testParsingMultis() {
        let bank = Bank(bytes: self.bankData)
        let lastMulti = bank.multis[Bank.multiPatchCount - 1]
        XCTAssertEqual(lastMulti.name, "Dwn@BgBryr")
    }
}

