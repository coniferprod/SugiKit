import XCTest

@testable import SugiKit

import SyxPack

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
        0x00, 0x00, 0x02, 0x03, // delay
        0x00, 0x00, 0x50, 0x40, // wave select h + ks curve
        0x12, 0x12, 0x7e, 0x7f, // wave select l
        0x4c, 0x4c, 0x5a, 0x5b, // coarse + key track
        0x00, 0x34, 0x02, 0x03, // fixed key
        0x2c, 0x37, 0x34, 0x35, // fine
        0x02, 0x02, 0x15, 0x11, // prs>frq sw + vib./a.bend sw + vel.curve
        
        // amplifier data (4 x 11 = 44 bytes)
        0x4b, 0x4b, 0x34, 0x35,  // Sn envelope level
        0x36, 0x36, 0x34, 0x35,  // Sn envelope attack
        0x48, 0x48, 0x34, 0x35,  // Sn envelope decay
        0x5a, 0x5a, 0x34, 0x35,  // Sn envelope sustain
        0x40, 0x40, 0x02, 0x01,  // Sn envelope release
        0x41, 0x41, 0x35, 0x36,  // Sn level mod vel
        0x32, 0x32, 0x35, 0x36,  // Sn level mod prs
        0x2c, 0x2c, 0x35, 0x36,  // Sn level mod ks
        0x32, 0x32, 0x35, 0x36,  // Sn time mod on vel
        0x32, 0x32, 0x35, 0x36,  // Sn time mod off vel
        0x32, 0x32, 0x33, 0x34,  // Sn time mod ks
                
        // filter data (2 x 14 = 28 bytes)
        0x31, 0x51,  // Fn cutoff
        0x02, 0x07,  // Fn resonance, LFO sw
        0x32, 0x34,  // Fn cutoff mod vel
        0x5b, 0x34,  // Fn cutoff mod prs
        0x32, 0x34,  // Fn cutoff mod krs
        0x36, 0x34,  // Fn dcf env dep
        0x32, 0x33,  // Fn dcf env vel dep
        0x56, 0x01,  // Fn dcf env attack
        0x64, 0x02,  // Fn dcf env decay
        0x32, 0x63,  // Fn dcf env sustain
        0x56, 0x01,  // Fn dcf env release
        0x32, 0x33,  // Fn dcf time mod on vel
        0x32, 0x33,  // Fn dcf time mode off vel
        0x32, 0x33,  // Fn dcf time mod ks
        
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
        switch SinglePatch.parse(from: self.patchData) {
        case .success(let patch):
            XCTAssertEqual(patch.name, PatchName("Melo Vox 1"))
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testVolume() {
        switch SinglePatch.parse(from: self.patchData) {
        case .success(let patch):
            XCTAssertEqual(patch.volume.value, 100)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testEffect() {
        switch SinglePatch.parse(from: self.patchData) {
        case .success(let patch):
            XCTAssertEqual(patch.effect.value, 1)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testSubmix() {
        switch SinglePatch.parse(from: self.patchData) {
        case .success(let patch):
            XCTAssertEqual(patch.submix, .g)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testActiveSources() {
        switch SinglePatch.parse(from: self.patchData) {
        case .success(let single):
            // This patch should have sources 1 and 2 active,
            // sources 3 and 4 muted.
            XCTAssert(single.sources[0].isActive && single.sources[1].isActive && !single.sources[2].isActive && !single.sources[3].isActive)
            // TODO: Still not sure which way it is in the SysEx
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    // Test S-COMMON parameters
    func testSourceCommonParameters() {
        switch SinglePatch.parse(from: self.patchData) {
        case .success(let single):
            let source = single.sources[0]
            XCTAssertEqual(source.delay.value, 0)
            XCTAssertEqual(source.velocityCurve, .curve1)
            XCTAssertEqual(source.keyScalingCurve, .curve1)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    // Test DCA parameters
    func testAmplifierParameters() {
        let ampData = self.patchData.slice(from: 58, length: Amplifier.dataSize * 4)
        let amp1Data = ampData.everyNthByte(n: 4, start: 0)
        switch Amplifier.parse(from: amp1Data) {
        case .success(let amp):
            XCTAssertEqual(amp.level.value, 0x4B)
            XCTAssertEqual(amp.envelope, self.amplifierEnvelope)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testAmplifierModulationParameters() {
        let ampData = self.patchData.slice(from: 58, length: Amplifier.dataSize * 4)
        let amp1Data = ampData.everyNthByte(n: 4, start: 0)
        switch Amplifier.parse(from: amp1Data) {
        case .success(let amp):
            let levelMod = amp.levelModulation
            XCTAssertEqual(levelMod.velocityDepth.value, 15)
            XCTAssertEqual(levelMod.pressureDepth.value, 0)
            XCTAssertEqual(levelMod.keyScalingDepth.value, -6)
        
            let timeMod = amp.timeModulation
            XCTAssertEqual(timeMod.attackVelocity.value, 0)
            XCTAssertEqual(timeMod.releaseVelocity.value, 0)
            XCTAssertEqual(timeMod.keyScaling.value, 0)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    // Test DCF parameters
    func testFilterParameters() {
        switch SinglePatch.parse(from: self.patchData) {
        case .success(let single):
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
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    // Test DCF MOD paramaters
    func testFilterModulationParameters() {
        switch SinglePatch.parse(from: self.patchData) {
        case .success(let single):
            let filter = single.filter1
        
            XCTAssertEqual(filter.envelopeDepth.value, 4)
            XCTAssertEqual(filter.envelopeVelocityDepth.value, 0)
            
            XCTAssertEqual(single.filter1.envelope, Filter.Envelope(attack: 86, decay: 100, sustain: 0, release: 86))
                                   
            let timeMod = filter.timeModulation
            XCTAssertEqual(timeMod.attackVelocity.value, 0)
            XCTAssertEqual(timeMod.releaseVelocity.value, 0)
            XCTAssertEqual(timeMod.keyScaling.value, 0)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    // Test source parameters
    func testSourceParameters() {
        let sourceData = self.patchData.slice(from: 30, length: Source.dataSize * 4)
        let s1Data = sourceData.everyNthByte(n: 4, start: 0)
        switch Source.parse(from: s1Data) {
        case .success(let source):
            XCTAssertEqual(source.wave.number, 19)
            XCTAssertEqual(source.keyTrack, true)
            XCTAssertEqual(source.coarse.value, -12)
            XCTAssertEqual(source.fine.value, -6)
            XCTAssertEqual(source.fixedKey.description, "C-1")
            XCTAssertEqual(source.pressureFrequency, false)
            XCTAssertEqual(source.vibrato, true)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    // Test LFO parameters
    func testLFOParameters() {
        switch SinglePatch.parse(from: self.patchData) {
        case .success(let single):
            XCTAssertEqual(single.vibrato, self.vibrato)
            XCTAssertEqual(single.lfo, self.lfo)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
}

