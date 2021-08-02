import XCTest
@testable import SugiKit

final class SugiKitTests: XCTestCase {
    func testWaveName() {
        let wave = Wave(number: 10)
        XCTAssertEqual(wave.name, "SAW 1")
    }

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
}

final class WaveTests: XCTestCase {
    func testWaveNumber() {
        let wave = Wave(number: 96)
        XCTAssertEqual(wave.number, 96)
    }
    
    func testWaveNumberFromSystemExclusive() {
        let highByte: Byte = 0b00000001
        let lowByte: Byte = 0x7f
        let number = Wave.numberFrom(highByte: highByte, lowByte: lowByte)
        XCTAssertEqual(number, 256)
    }
    
    func testWaveName() {
        let wave = Wave(number: 1)
        XCTAssertEqual(wave.name, "SIN 1ST")
    }
}
