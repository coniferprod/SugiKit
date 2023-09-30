import XCTest
@testable import SugiKit
import SyxPack

final class DrumTests: XCTestCase {
    var bytes = ByteArray()
    
    // The starting offset of the drum block
    let drumStartOffset =
        Bank.singlePatchCount * SinglePatch.dataSize +  // 64 single patches
        Bank.multiPatchCount * MultiPatch.dataSize // 64 multi patches
    
    // Called before each test method begins
    override func setUp() {
        guard let message = Message(data: a401Bytes) else {
            XCTFail("Not a valid System Exclusive message")
            return
        }
        
        // SysEx message parsed, now payload should be 15123 - (8 + 1) = 15114
        self.bytes = ByteArray(message.payload.suffix(from: Header.dataSize))
    }

    var drum: Result<Drum, ParseError> {
        return Drum.parse(from: bytes.slice(from: drumStartOffset, length: Drum.dataSize))
    }
    
    func testVolume() {
        switch self.drum {
        case .success(let drum):
            XCTAssertEqual(drum.common.volume.value, 100)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testChannel() {
        switch self.drum {
        case .success(let drum):
            XCTAssertEqual(drum.common.channel.value, 10)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testVelocityDepth() {
        switch self.drum {
        case .success(let drum):
            XCTAssertEqual(drum.common.velocityDepth.value, 50)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testNoteParameters() {
        switch self.drum {
        case .success(let drum):
            let note = drum.notes[0]  // this is the C1 drum note

            // hex: 70 01 60 3f 46 17 10 00 64 55
            let otherNote = Drum.Note(
                submix: .h,
                source1: Drum.Source(wave: Wave(number: 97), decay: 70, tune: -34, level: 100),
                source2: Drum.Source(wave: Wave(number: 192), decay: 23, tune: -50, level: 85)
            )

            XCTAssertEqual(note, otherNote)
            
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testSystemExclusiveDataLength() {
        let drum = Drum()
        XCTAssertEqual(drum.asData().count, Drum.dataSize)
    }
}
