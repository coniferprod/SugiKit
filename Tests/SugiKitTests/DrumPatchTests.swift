import XCTest
@testable import SugiKit

final class DrumPatchTests: XCTestCase {
    var bytes = ByteArray()
    var bank: Bank?
    
    // Called before each test method begins
    override func setUp() {
        self.bytes = ByteArray(a401Bytes)
        self.bank = Bank(bytes: self.bytes)
    }
    
    func testVolume() {
        let drum = bank!.drum
        XCTAssertEqual(drum.common.volume, 100)
    }
    
    func testChannel() {
        let drum = bank!.drum
        XCTAssertEqual(drum.common.channel, 10)
    }

    func testVelocityDepth() {
        let drum = bank!.drum
        XCTAssertEqual(drum.common.velocityDepth, 50)
    }
    
    func testNoteParameters() {
        let drum = bank!.drum

        let note = drum.notes[0]  // this is the C1 drum note
        
        // hex: 70 01 60 3f 46 17 10 00 64 55
        XCTAssertEqual(note.source1.waveNumber, 97)
        XCTAssertEqual(note.source2.waveNumber, 192)

        XCTAssertEqual(note.source1.decay, 70)
        XCTAssertEqual(note.source2.decay, 23)
        
        XCTAssertEqual(note.source1.tune, -34)
        XCTAssertEqual(note.source2.tune, -50)

        XCTAssertEqual(note.source1.level, 100)
        XCTAssertEqual(note.source2.level, 85)

        XCTAssertEqual(note.submix, .h)

    }
}

