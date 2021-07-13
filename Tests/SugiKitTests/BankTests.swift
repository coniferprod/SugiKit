import XCTest

@testable import SugiKit

final class BankTests: XCTestCase {
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
    }

    func testInit() {
        print("Initializing bank from \(self.bankData.count) bytes of data")
        let bank = Bank(bytes: self.bankData)
        XCTAssertEqual(bank.singles.count, 64)
        XCTAssertEqual(bank.multis.count, 64)
        XCTAssertEqual(bank.effects.count, 32)
    }
}
