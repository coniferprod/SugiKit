import XCTest
@testable import SugiKit
import SyxPack

final class EffectPatchTests: XCTestCase {
    var bytes = ByteArray()
    
    // The starting offset of the effect patch block
    let effectStartOffset =
        Bank.singlePatchCount * SinglePatch.dataSize  // 64 single patches
        + Bank.multiPatchCount * MultiPatch.dataSize // 64 multi patches
        + Drum.dataSize
    
    var effects = [EffectPatch]()
    
    // Called before each test method begins
    override func setUp() {
        guard let message = Message(data: a401Bytes) else {
            XCTFail("Not a valid System Exclusive message")
            return
        }
        
        // SysEx message parsed, now payload should be 15123 - (8 + 1) = 15114
        self.bytes = ByteArray(message.payload.suffix(from: Header.dataSize))

        var offset = effectStartOffset
        for _ in 0..<Bank.effectPatchCount {
            let effectData = self.bytes.slice(from: offset, length: EffectPatch.dataSize)
            switch EffectPatch.parse(from: effectData) {
            case .success(let patch):
                self.effects.append(patch)
            case .failure(let error):
                XCTFail("\(error)")
            }
            offset += EffectPatch.dataSize
        }
    }
    
    func testEffectType() {
        XCTAssertEqual(effects[0].effect, .reverb1)
    }
    
    func testEffectParameters() {
        let effect = effects[0]
        XCTAssertEqual(effect.param1, 7)  // PRE.DELAY = 7
        XCTAssertEqual(effect.param2, 5)  // REV.TIME = 5
        XCTAssertEqual(effect.param3, 31) // TONE = 31
    }
    
    /*
     00 = effect type
     07 = param1
     05 = param2
     1f = param3
     04 05 06 07 08 40 = six dummy bytes
     
     submix A:
     00 = pan
     2d = send1 (dec 45)
     00 = send2
     
     submix B:
     03 2d 00
     
     submix C:
     0b 2d 00
     
     submix D:
     0e 2d 00
     
     submix E:
     00 64 00
     
     submix F:
     0e 64 00
     
     submix G:
     07 64 64
     
     submix H:
     07 06 00
     
     30 = checksum
     */
    
    func testSubmixParameters() {
        let effect = effects[0]
        let submix = effect.submixes[0]
        XCTAssertEqual(submix.pan, -7)
        XCTAssertEqual(submix.send1, 45)
        XCTAssertEqual(submix.send2, 0)
    }
    
    func testDescription() {
        let effect = effects[0]
        
        let expected = """
        Reverb 1: Pre. Delay=7  Rev. Time=5  Tone=31
          A: Pan=-7 Send1=45 Send2=0
          B: Pan=-4 Send1=45 Send2=0
          C: Pan=4 Send1=45 Send2=0
          D: Pan=7 Send1=45 Send2=0
          E: Pan=-7 Send1=100 Send2=0
          F: Pan=7 Send1=100 Send2=0
          G: Pan=0 Send1=100 Send2=100
          H: Pan=0 Send1=6 Send2=0
        """
        let actual = effect.description
        XCTAssertEqual(actual, expected)
    }
}
