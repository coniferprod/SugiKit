import XCTest
@testable import SugiKit

final class SugiKitTests: XCTestCase {
    func testDecodeWaveNumber() {
        let note = DrumNote()

        let msb: Byte = 0x70
        XCTAssertEqual(note.decodeWaveNumber(msb: msb.bitField(start: 0, end: 1), lsb: 0x60), 97)
    }

    func testEncodeWaveNumber() {
        let note = DrumNote()

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

// Test cases related to parsing System Exclusive files to get domain objects.
final class AbsorptionTests: XCTestCase {
    var bytes = ByteArray()
    
    // Called before each test method begins
    override func setUp() {
        self.bytes = ByteArray(a401Bytes)
        
        // If you wanted to drop the header and terminator:
        //bytes = ByteArray(bytes.dropFirst(headerLength)) // lose the header
        //_ = bytes.dropLast()  // lose the terminator
        // now we would have 15123 - 8 - 1 = 15114 bytes of data
    }

    func testParsingBank() {
        let bank = Bank(bytes: self.bytes)
        XCTAssertEqual(bank.singles.count, Bank.singlePatchCount)
        XCTAssertEqual(bank.multis.count, Bank.multiPatchCount)
        XCTAssertEqual(bank.effects.count, Bank.effectPatchCount)
    }

    func testParsingSingles() {
        let bank = Bank(bytes: self.bytes)
        let firstSingle = bank.singles[0]
        XCTAssertEqual(firstSingle.name, "Melo Vox 1")
    }

    func testParsingMultis() {
        let bank = Bank(bytes: self.bytes)
        let lastMulti = bank.multis[Bank.multiPatchCount - 1]
        XCTAssertEqual(lastMulti.name, "Dwn@BgBryr")
    }
}

// Test cases related to generating System Exclusive files from domain objects.
final class EmissionTests: XCTestCase {
    override class func setUp() {

    }

    func testAddition() {
        XCTAssertEqual(2 + 2, 4)
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
