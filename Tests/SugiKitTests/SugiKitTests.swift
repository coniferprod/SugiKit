import XCTest
@testable import SugiKit

final class SugiKitTests: XCTestCase {
    func testDecodeWaveNumber() {
        let note = Drum.Note()

        let msb: Byte = 0x70
        XCTAssertEqual(note.decodeWaveNumber(msb: msb.bitField(start: 0, end: 1), lsb: 0x60), 97)
    }

    func testEncodeWaveNumber() {
        let note = Drum.Note()

        let (highByte, lowByte) = note.encodeWaveNumber(waveNumber: 97)
        XCTAssertEqual(highByte, 0x00)
        XCTAssertEqual(lowByte, 0x60)
    }

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
