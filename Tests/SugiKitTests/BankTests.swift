import XCTest

@testable import SugiKit

import SyxPack

final class BankTests: XCTestCase {
    var bankData = ByteArray()
    
    override func setUp() {
        /*
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
        */
        // Seems that resources still don't work in Xcode 12.5.1, so use raw bytes from A401Bytes.swift:
        let dataBytes = a401Bytes

        self.bankData = dataBytes.slice(from: SugiMessage.Header.dataSize, length: dataBytes.count - (SugiMessage.Header.dataSize + 1))
    }

    func testInit() {
        print("Initializing bank from \(self.bankData.count) bytes of data")
        let bank = Bank(bytes: self.bankData)
        XCTAssertEqual(bank.singles.count, 64)
        XCTAssertEqual(bank.multis.count, 64)
        XCTAssertEqual(bank.effects.count, 32)
    }
    
    func testSinglesLength() {
        let bank = Bank(bytes: self.bankData)
        var buffer = ByteArray()
        bank.singles.forEach { buffer.append(contentsOf: $0.asData()) }
        XCTAssertEqual(buffer.count, Bank.singlePatchCount * SinglePatch.dataSize)
    }
    
    func testMultisLength() {
        let bank = Bank(bytes: self.bankData)
        var buffer = ByteArray()
        bank.multis.forEach { buffer.append(contentsOf: $0.asData()) }
        XCTAssertEqual(buffer.count, Bank.multiPatchCount * MultiPatch.dataSize)
    }
    
    func testDrumLength() {
        let bank = Bank(bytes: self.bankData)
        var buffer = ByteArray()
        buffer.append(contentsOf: bank.drum.asData())
        XCTAssertEqual(buffer.count, Drum.dataSize)
    }
    
    func testEffectLength() {
        let bank = Bank(bytes: self.bankData)
        var buffer = ByteArray()
        bank.effects.forEach { buffer.append(contentsOf: $0.asData()) }
        XCTAssertEqual(buffer.count, Bank.effectPatchCount * EffectPatch.dataSize)
    }
    
    // The SYX files have junk in them, so there is no point really to compare
    // the byte representations. Maybe emit SysEx bytes, parse them back and
    // then compare the data model representations instead?
    // The most important thing in the emitted SysEx is that the checksum is right,
    // so that the K4 will accept the dump.
    
    /*
    func testRoundtrip() {
        let originalBank = Bank(bytes: self.bankData)
        
        let emittedBytes = originalBank.systemExclusiveData
        let currentBank = Bank(bytes: emittedBytes)
        
        XCTAssertEqual(currentBank, originalBank)
    }
    */
    
}
