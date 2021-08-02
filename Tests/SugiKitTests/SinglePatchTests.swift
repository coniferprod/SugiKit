import XCTest

@testable import SugiKit

final class SinglePatchTests: XCTestCase {
    var filterEnvelope: Filter.Envelope?
    var amplifierEnvelope: Amplifier.Envelope?
    var vibrato: Vibrato?
    var lfo: LFO?
    
    // This is the data of the single patch A-1 from A4-01.SYX
    // (called "Melo Vox 1").
    let patchData: ByteArray = [
        0x4d, 0x65, 0x6c, 0x6f, 0x20, 0x56, 0x6f, 0x78, 0x20, 0x31,  // s00...s09 = name
        0x64, // s10: volume
        0x20, // s11: effect
        0x06, // s12: submix
        0x04, // s13: source mode, polyphony mode, AM1>2, AM3>4
        0x0c, // s14: active sources + 1st byte of vibrato settings
        
        // s15: bender range, wheel assign
        0x02,  // 0b00000010
        
        0x1c, // s16: 2nd vibrato byte
        0x3f, // s17: wheel depth
        0x39, 0x31, 0x32, 0x32, // s18...s21: auto bend
        0x32, // s22: 3rd vibrato byte
        0x3d, // s23: 4th and last vibrato byte
        0x00, 0x30, 0x00, 0x32, 0x32, // LFO bytes, five in total
        0x32, // press freq

        // source data (4 x 7 = 28 bytes)
        0x00, 0x00, 0x02, 0x03, 0x00, 0x00, 0x50,
        0x40, 0x12, 0x12, 0x7e, 0x7f, 0x4c, 0x4c,
        0x5a, 0x5b, 0x00, 0x34, 0x02, 0x03, 0x2c,
        0x37, 0x34, 0x35, 0x02, 0x02, 0x15, 0x11,
        
        // amplifier data (4 x 11 = 44 bytes)
        0x4b, 0x4b, 0x34, 0x35, 0x36, 0x36, 0x34, 0x35, 0x48, 0x48, 0x34,
        0x35, 0x5a, 0x5a, 0x34, 0x35, 0x40, 0x40, 0x02, 0x01, 0x41, 0x41,
        0x35, 0x36, 0x32, 0x32, 0x35, 0x36, 0x2c, 0x2c, 0x35, 0x36, 0x32,
        0x32, 0x35, 0x36, 0x32, 0x32, 0x35, 0x36, 0x32, 0x32, 0x33, 0x34,
                
        // filter data (2 x 14 = 28 bytes)
        0x31, 0x51, 0x02, 0x07, 0x32, 0x34, 0x5b,
        0x34, 0x32, 0x34, 0x36, 0x34, 0x32, 0x33,
        0x56, 0x01, 0x64, 0x02, 0x32, 0x63, 0x56,
        0x01, 0x32, 0x33, 0x32, 0x33, 0x32, 0x33,
        
        // checksum
        0x6e
    ]

    override func setUp() {
        self.filterEnvelope = Filter.Envelope(attack: 86, decay: 100, sustain: 0, release: 86)
        self.amplifierEnvelope = Amplifier.Envelope(attack: 54, decay: 72, sustain: 90, release: 64)
        self.vibrato = Vibrato(shape: .triangle, speed: 28, depth: 11, pressureDepth: 0)
        self.lfo = LFO(shape: .triangle, speed: 48, delay: 0, depth: 0, pressureDepth: 0)
    }
    
    func testName() {
        let single = SinglePatch(bytes: self.patchData)
        XCTAssertEqual(single.name, "Melo Vox 1")
    }
    
    func testVolume() {
        let single = SinglePatch(bytes: self.patchData)
        XCTAssertEqual(single.volume, 100)
    }
    
    func testEffect() {
        let single = SinglePatch(bytes: self.patchData)
        XCTAssertEqual(single.effect, 1)
    }
    
    func testSubmix() {
        let single = SinglePatch(bytes: self.patchData)
        XCTAssertEqual(single.submix, .g)
    }
    
    func testActiveSources() {
        // This patch should have sources 1 and 2 active,
        // sources 3 and 4 muted.
        let single = SinglePatch(bytes: self.patchData)
        XCTAssertEqual(single.activeSources, [true, true, false, false])
        // TODO: Still not sure which way it is in the SysEx
    }
    
    // Test COMMON parameters
    func testCommonParameters() {
        let single = SinglePatch(bytes: self.patchData)

        XCTAssertEqual(single.sourceMode, .normal)
        XCTAssertEqual(single.am12, false)
        XCTAssertEqual(single.am34, false)
        XCTAssertEqual(single.polyphonyMode, .poly2)
        XCTAssertEqual(single.benderRange, 2)
        XCTAssertEqual(single.pressFreq, 0)
        
        XCTAssertEqual(single.wheelAssign, .vibrato)
        XCTAssertEqual(single.wheelDepth, 13)
        
        var autoBend = AutoBend(time: 57, depth: -1, keyScalingTime: 0, velocityDepth: 0)
        XCTAssertEqual(single.autoBend, autoBend)
    }
    
    // Test S-COMMON parameters
    func testSourceCommonParameters() {
        let single = SinglePatch(bytes: self.patchData)
        let source = single.sources[0]

        XCTAssertEqual(source.delay, 0)
        XCTAssertEqual(source.velocityCurve, .curve1)
        XCTAssertEqual(source.keyScalingCurve, .curve1)
    }
    
    // Test DCA parameters
    func testAmplifierParameters() {
        let single = SinglePatch(bytes: self.patchData)
        let amp = single.amplifiers[0]
        XCTAssertEqual(amp.level, 75)
        
        XCTAssertEqual(amp.envelope, self.amplifierEnvelope)
    }
    
    func testAmplifierModulationParameters() {
        let single = SinglePatch(bytes: self.patchData)
        let amp = single.amplifiers[0]
        let levelMod = amp.levelModulation
        XCTAssertEqual(levelMod.velocityDepth, 15)
        XCTAssertEqual(levelMod.pressureDepth, 0)
        XCTAssertEqual(levelMod.keyScalingDepth, -6)
        
        let timeMod = amp.timeModulation
        XCTAssertEqual(timeMod.attackVelocity, 0)
        XCTAssertEqual(timeMod.releaseVelocity, 0)
        XCTAssertEqual(timeMod.keyScaling, 0)
    }
    
    // Test DCF parameters
    func testFilterParameters() {
        let single = SinglePatch(bytes: self.patchData)
        let filter = Filter(
            cutoff: 49,
            resonance: 2,
            cutoffModulation: LevelModulation(velocityDepth: 0, pressureDepth: 41, keyScalingDepth: 0),
            isLfoModulatingCutoff: false,
            envelopeDepth: 4,
            envelopeVelocityDepth: 0,
            envelope: Filter.Envelope(attack: 86, decay: 100, sustain: 0, release: 86),
            timeModulation: TimeModulation(attackVelocity: 0, releaseVelocity: 0, keyScaling: 0))

        XCTAssertEqual(single.filter1, filter)
    }
    
    // Test DCF MOD paramaters
    func testFilterModulationParameters() {
        let single = SinglePatch(bytes: self.patchData)
        let filter = single.filter1
        
        XCTAssertEqual(filter.envelopeDepth, 4)
        XCTAssertEqual(filter.envelopeVelocityDepth, 0)
        
        XCTAssertEqual(single.filter1.envelope, Filter.Envelope(attack: 86, decay: 100, sustain: 0, release: 86))
                               
        let timeMod = filter.timeModulation
        XCTAssertEqual(timeMod.attackVelocity, 0)
        XCTAssertEqual(timeMod.releaseVelocity, 0)
        XCTAssertEqual(timeMod.keyScaling, 0)
    }
    
    // Test DCO parameters
    func testOscillatorParameters() {
        let single = SinglePatch(bytes: self.patchData)
        let source = single.sources[0]
        XCTAssertEqual(source.wave.number, 19)
        XCTAssertEqual(source.keyTrack, true)
        XCTAssertEqual(source.coarse, -12)
        XCTAssertEqual(source.fine, -6)
        XCTAssertEqual(source.fixedKey.description, "C-1")
        XCTAssertEqual(source.pressureFrequency, false)
        XCTAssertEqual(source.vibrato, true)
    }
    
    // Test LFO parameters
    func testLFOParameters() {
        let single = SinglePatch(bytes: self.patchData)
        XCTAssertEqual(single.vibrato, self.vibrato)
        XCTAssertEqual(single.lfo, self.lfo)
    }
    
    func testDescription() {
        let single = SinglePatch(bytes: self.patchData)
        let desc = single.description
        print(desc)
        XCTAssert(desc.length != 0)
    }
}