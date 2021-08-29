import XCTest

@testable import SugiKit

final class MultiPatchTests: XCTestCase {
    var bytes = ByteArray()
    
    // The starting offset of the multi patch block
    let multiStartOffset = 8 // SysEx header length
        + Bank.singlePatchCount * SinglePatch.dataSize  // 64 single patches
    
    var multis = [MultiPatch]()
    
    // Called before each test method begins
    override func setUp() {
        self.bytes = a401Bytes
        self.multis = [MultiPatch]()
        var offset = multiStartOffset
        for _ in 0..<Bank.multiPatchCount {
            self.multis.append(MultiPatch(bytes: self.bytes.slice(from: offset, length: MultiPatch.dataSize)))
            offset += MultiPatch.dataSize
        }
    }
    
    func testLength() {
        XCTAssertEqual(multis[0].systemExclusiveData.count, MultiPatch.dataSize)
    }
    
    func testName() {
        XCTAssertEqual(multis[0].name, "Fatt!Anna5")
    }
    
    func testNameWithTrailingNul() {
        let bankBytes = a403Bytes
        var bankMultis = [MultiPatch]()
        var offset = multiStartOffset
        for _ in 0..<Bank.multiPatchCount {
            bankMultis.append(MultiPatch(bytes: bankBytes.slice(from: offset, length: MultiPatch.dataSize)))
            offset += MultiPatch.dataSize
        }
        let multi = bankMultis[8]  // pick up multi A-9
        
        // trailing NUL should be replaced by SPACE
        XCTAssertEqual(multi.name, "Solo Now! ");
    }

    func testVolume() {
        XCTAssertEqual(multis[0].volume, 80)
    }

    func testEffect() {
        XCTAssertEqual(multis[0].effect, 11)
    }

    func testSectionInstrumentParameters() {
        let section1 = multis[0].sections[0]
        let section2 = multis[0].sections[1]

        XCTAssertEqual(section1.singlePatchNumber, 14)  // IA-15 YorFatnes8
        XCTAssertEqual(section2.singlePatchNumber, 63)  // ID-16 Taurs4Pole
    }
    
    func testSectionZoneParameters() {
        let section = multis[0].sections[0]
        XCTAssertEqual(section.zone.low, 0)  // C-2
        XCTAssertEqual(section.zone.high, 127) // G8
        XCTAssertEqual(section.velocitySwitch, .all)  // see testByteM15Parsing()
    }

    // The Kawai K4 multi editing has velocity switch options organized
    // as SOFT, LOUD, ALL. That gives me the impression that they would
    // also be like that in the SysEx, even though the MIDI implementation
    // says "0/all, 1/soft, 2/loud". If so, then that should actually be
    // "0/soft, 1/loud, 2/all". Let's parse it like that and see.
    func testByteM15Parsing() {
        let b: Byte = 0x20
        let channel = Int(b.bitField(start: 0, end: 4) + 1)
        let vs = b.bitField(start: 4, end: 6)
        print("vs = \(vs.toHex(digits: 2))")
        var velocitySwitch: VelocitySwitch = .all
        switch vs {
        case 0:
            velocitySwitch = .soft
        case 1:
            velocitySwitch = .loud
        case 2:
            velocitySwitch = .all
        default:
            velocitySwitch = .all
        }
        
        let isMuted = b.isBitSet(6)

        XCTAssertEqual(velocitySwitch, .all)
        XCTAssertEqual(channel, 1)
        XCTAssertEqual(isMuted, false)
    }
    // Since this test passes, it looks like there is an error
    // in the MIDI implementation document. The SugiKit multi parsing
    // should now correct this error.
    
    func testSectionChannelParameters() {
        let section = multis[0].sections[0]
        XCTAssertEqual(section.channel, 1)
    }
    
    func testSectionLevelParameters() {
        let section = multis[0].sections[0]
        XCTAssertEqual(section.level, 100)
        XCTAssertEqual(section.transpose, 0)
        XCTAssertEqual(section.tune, 0)
        XCTAssertEqual(section.submix, .e)
    }
    
    // This test depends on a System Exclusive file found in the Resources directory of the test module.
    /*
    func testMultiPatch_fromData() {
        if let patchURL = Bundle.module.url(forResource: "A401", withExtension: "SYX") {
            if let patchData = try? Data(contentsOf: patchURL) {
                let bank = Bank(bytes: ByteArray(patchData))
                let multi = bank.multis[0]
                XCTAssert(multi.name == "Fatt!Anna5")
            }
        }
    }
    */
}
