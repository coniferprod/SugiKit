import XCTest

@testable import SugiKit

final class SinglePatchTests: XCTestCase {
    var bytes = ByteArray()
    var bank: Bank?
    
    // Called before each test method begins
    override func setUp() {
        self.bytes = ByteArray(a401Bytes)
        self.bank = Bank(bytes: self.bytes)
    }
    
    func testName() {
        let single = bank!.singles[0]
        XCTAssertEqual(single.name, "Melo Vox 1")
    }
    
    func testVolume() {
        let single = bank!.singles[0]
        XCTAssertEqual(single.volume, 100)
    }
    
    func testEffect() {
        let single = bank!.singles[0]
        
        XCTAssertEqual(single.effect, 1)
    }
    
    func testSubmix() {
        let single = bank!.singles[0]
        XCTAssertEqual(single.submix, .g)
    }
    
    func testActiveSources() {
        // This patch should have sources 1 and 2 active,
        // sources 3 and 4 muted.
        let single = bank!.singles[0]
        XCTAssertEqual(single.activeSources, [true, true, false, false])
        // TODO: Still not sure which way it is in the SysEx
    }
    
    // Test COMMON parameters
    func testCommonParameters() {
        let single = bank!.singles[0]

        XCTAssertEqual(single.sourceMode, .normal)
        XCTAssertEqual(single.am12, false)
        XCTAssertEqual(single.am34, false)
        XCTAssertEqual(single.polyphonyMode, .poly2)
        XCTAssertEqual(single.benderRange, 2)
        XCTAssertEqual(single.pressFreq, 0)
        
        XCTAssertEqual(single.wheelAssign, .vibrato)
        XCTAssertEqual(single.wheelDepth, 13)
        XCTAssertEqual(single.autoBend.time, 57)
        XCTAssertEqual(single.autoBend.depth, -1)
        XCTAssertEqual(single.autoBend.keyScalingTime, 0)
        XCTAssertEqual(single.autoBend.velocityDepth, 0)
    }
    
    // Test S-COMMON parameters
    func testSourceCommonParameters() {
        let single = bank!.singles[0]
        let source = single.sources[0]

        XCTAssertEqual(source.delay, 0)
        XCTAssertEqual(source.velocityCurve, .curve1)
        XCTAssertEqual(source.keyScalingCurve, .curve1)
    }
    
    // Test DCA parameters
    func testAmplifierParameters() {
        let single = bank!.singles[0]
        let amp = single.amplifiers[0]
        XCTAssertEqual(amp.level, 75)
        
        let env = amp.envelope
        XCTAssertEqual(env.attack, 54)
        XCTAssertEqual(env.decay, 72)
        XCTAssertEqual(env.sustain, 90)
        XCTAssertEqual(env.release, 64)
    }
    
    func testAmplifierModulationParameters() {
        let single = bank!.singles[0]
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
        let single = bank!.singles[0]
        let filter = single.filter1
        XCTAssertEqual(filter.cutoff, 49)
        XCTAssertEqual(filter.resonance, 2)
        
        let cutoffMod = filter.cutoffModulation
        XCTAssertEqual(cutoffMod.velocityDepth, 0)
        XCTAssertEqual(cutoffMod.pressureDepth, 41)
        XCTAssertEqual(cutoffMod.keyScalingDepth, 0)
        
        XCTAssertEqual(filter.isLfoModulatingCutoff, false)
    }
    
    // Test DCF MOD paramaters
    func testFilterModulationParameters() {
        let single = bank!.singles[0]
        let filter = single.filter1
        
        XCTAssertEqual(filter.envelopeDepth, 4)
        XCTAssertEqual(filter.envelopeVelocityDepth, 0)
        
        let env = filter.envelope
        XCTAssertEqual(env.attack, 86)
        XCTAssertEqual(env.decay, 100)
        XCTAssertEqual(env.sustain, 0)
        XCTAssertEqual(env.release, 86)
        
        let timeMod = filter.timeModulation
        XCTAssertEqual(timeMod.attackVelocity, 0)
        XCTAssertEqual(timeMod.releaseVelocity, 0)
        XCTAssertEqual(timeMod.keyScaling, 0)
    }
    
    // Test DCO parameters
    func testOscillatorParameters() {
        let single = bank!.singles[0]
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
        let single = bank!.singles[0]
        let vib = single.vibrato
        XCTAssertEqual(vib.shape, .triangle)
        XCTAssertEqual(vib.speed, 28)
        XCTAssertEqual(vib.depth, 11)
        XCTAssertEqual(vib.pressureDepth, 0)
        
        let lfo = single.lfo
        XCTAssertEqual(lfo.shape, .triangle)
        XCTAssertEqual(lfo.speed, 48)
        XCTAssertEqual(lfo.delay, 0)
        XCTAssertEqual(lfo.depth, 0)
        XCTAssertEqual(lfo.pressureDepth, 0)
    }
    
    func testDescription() {
        let single = bank!.singles[0]
        let desc = single.description
        print(desc)
        XCTAssert(desc.length != 0)
    }
    
    // This test depends on a System Exclusive file found in the Resources directory of the test module.
    func testSinglePatch_fromData() {
        if let patchURL = Bundle.module.url(forResource: "A401", withExtension: "SYX") {
            if let patchData = try? Data(contentsOf: patchURL) {
                let patch = SinglePatch(bytes: patchData.bytes)
                XCTAssert(patch.name == "Melo Vox 1")
            }
        }
    }
}

