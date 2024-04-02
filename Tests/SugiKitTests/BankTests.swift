import XCTest

@testable import SugiKit

import ByteKit
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
        guard let message = Message(data: a401Bytes) else {
            XCTFail("Not a valid System Exclusive message")
            return
        }
        
        // SysEx message parsed, now payload should be 15123 - (8 + 1) = 15114
        self.bankData = ByteArray(message.payload.suffix(from: Header.dataSize))
    }

    func testInit() {
        switch Bank.parse(from: self.bankData) {
        case .success(let bank):
            XCTAssertEqual(bank.singles.count, 64)
            XCTAssertEqual(bank.multis.count, 64)
            XCTAssertEqual(bank.effects.count, 32)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testSinglesLength() {
        switch Bank.parse(from: self.bankData) {
        case .success(let bank):
            var buffer = ByteArray()
            bank.singles.forEach { buffer.append(contentsOf: $0.asData()) }
            XCTAssertEqual(buffer.count, Bank.singlePatchCount * SinglePatch.dataSize)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testMultisLength() {
        switch Bank.parse(from: self.bankData) {
        case .success(let bank):
            var buffer = ByteArray()
            bank.multis.forEach { buffer.append(contentsOf: $0.asData()) }
            XCTAssertEqual(buffer.count, Bank.multiPatchCount * MultiPatch.dataSize)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testMultiCount() {
        switch Bank.parse(from: self.bankData) {
        case .success(let bank):
            XCTAssertEqual(bank.multis.count, Bank.multiPatchCount)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDrumLength() {
        switch Bank.parse(from: self.bankData) {
        case .success(let bank):
            var buffer = ByteArray()
            buffer.append(contentsOf: bank.drum.asData())
            XCTAssertEqual(buffer.count, Drum.dataSize)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testEffectLength() {
        switch Bank.parse(from: self.bankData) {
        case .success(let bank):
            var buffer = ByteArray()
            bank.effects.forEach { buffer.append(contentsOf: $0.asData()) }
            XCTAssertEqual(buffer.count, Bank.effectPatchCount * EffectPatch.dataSize)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testParseBankSingle() {
        let singlePatchData = self.bankData.slice(from: 0, length: SinglePatch.dataSize)
        
        switch SinglePatch.parse(from: singlePatchData) {
        case .success(let singlePatch):
            switch Bank.parse(from: self.bankData) {
            case .success(let bank):
                XCTAssertEqual(singlePatch.filter1, bank.singles[0].filter1)
            case .failure(let error):
                XCTFail("\(error)")
            }
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
}
