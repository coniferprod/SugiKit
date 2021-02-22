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

final class SinglePatchTests: XCTestCase {
    var bytes = ByteArray()
    
    // Called before each test method begins
    override func setUp() {
        self.bytes = ByteArray(a401Bytes)
        
        // If you wanted to drop the header and terminator:
        //bytes = ByteArray(bytes.dropFirst(headerLength)) // lose the header
        //_ = bytes.dropLast()  // lose the terminator
        // now we would have 15123 - 8 - 1 = 15114 bytes of data
    }
    
    func testVolume() {
        let bank = Bank(bytes: self.bytes)
        let single = bank.singles[0]
        print(single)
        XCTAssertEqual(single.volume, 0x64)        
    }
    
    func testEffect() {
        let bank = Bank(bytes: self.bytes)
        let single = bank.singles[0]
        
        XCTAssertEqual(single.effect, 32)
    }

}
