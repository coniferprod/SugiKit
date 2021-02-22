import XCTest
@testable import SugiKit

final class SugiKitTests: XCTestCase {
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
    
    func testWaveName() {
        let wave = Wave(number: 10)
        XCTAssertEqual(wave.name, "SAW 1")
    }
    
    func testNoteName() {
        XCTAssertEqual(Source.noteName(for: 60), "C4")
    }
    
    func testKeyNumber() {
        XCTAssertEqual(Source.keyNumber(for: "C4"), 60)
    }
    
    func testEmptyBankCreation() {
        let bank = Bank()
        XCTAssertEqual(bank.singles.count, Bank.singlePatchCount)
        XCTAssertEqual(bank.multis.count, Bank.multiPatchCount)
        XCTAssertEqual(bank.effects.count, Bank.effectPatchCount)

    }
}
