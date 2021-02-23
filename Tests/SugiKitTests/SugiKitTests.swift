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
    var bank: Bank?
    
    // Called before each test method begins
    override func setUp() {
        self.bytes = ByteArray(a401Bytes)
        self.bank = Bank(bytes: self.bytes)
        
        // If you wanted to drop the header and terminator:
        //bytes = ByteArray(bytes.dropFirst(headerLength)) // lose the header
        //_ = bytes.dropLast()  // lose the terminator
        // now we would have 15123 - 8 - 1 = 15114 bytes of data
    }
    
    func testVolume() {
        let single = bank!.singles[0]
        print(single)
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
        let source = single.sources[0]
        
        let amp = source.amplifier
        XCTAssertEqual(amp.level, 75)
        
        let env = amp.envelope
        XCTAssertEqual(env.attack, 54)
        XCTAssertEqual(env.decay, 72)
        XCTAssertEqual(env.sustain, 90)
        XCTAssertEqual(env.release, 64)
    }
    
    func testAmplifierModulationParameters() {
        let single = bank!.singles[0]
        let source = single.sources[0]
        
        let amp = source.amplifier
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
        let osc = source.oscillator
        XCTAssertEqual(osc.waveNumber, 19)
        XCTAssertEqual(osc.keyTrack, true)
        XCTAssertEqual(osc.coarse, -12)
        XCTAssertEqual(osc.fine, -6)
        XCTAssertEqual(osc.fixedKey, "C-1")
        XCTAssertEqual(osc.pressureFrequency, false)
        XCTAssertEqual(osc.vibrato, true)
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
}
