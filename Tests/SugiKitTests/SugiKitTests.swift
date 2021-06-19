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
}

final class MultiPatchTests: XCTestCase {
    var bytes = ByteArray()
    var bank: Bank?
    
    // Called before each test method begins
    override func setUp() {
        self.bytes = ByteArray(a401Bytes)
        self.bank = Bank(bytes: self.bytes)
    }
    
    func testName() {
        let multi = bank!.multis[0]
        XCTAssertEqual(multi.name, "Fatt!Anna5")
    }

    func testVolume() {
        let multi = bank!.multis[0]
        XCTAssertEqual(multi.volume, 80)
    }

    func testEffect() {
        let multi = bank!.multis[0]
        XCTAssertEqual(multi.effect, 11)
    }

    func testSectionInstrumentParameters() {
        let multi = bank!.multis[0]
        let section1 = multi.sections[0]
        let section2 = multi.sections[1]

        XCTAssertEqual(section1.singlePatchNumber, 14)  // IA-15 YorFatnes8
        XCTAssertEqual(section2.singlePatchNumber, 63)  // ID-16 Taurs4Pole

    }
    
    func testSectionZoneParameters() {
        let multi = bank!.multis[0]
        let section = multi.sections[0]
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
        let multi = bank!.multis[0]
        let section = multi.sections[0]
        XCTAssertEqual(section.channel, 1)
    }
    
    func testSectionLevelParameters() {
        let multi = bank!.multis[0]
        let section = multi.sections[0]
        XCTAssertEqual(section.level, 100)
        XCTAssertEqual(section.transpose, 0)
        XCTAssertEqual(section.tune, 0)
        XCTAssertEqual(section.submix, .e)
    }
}

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
        XCTAssertEqual(drum.volume, 100)
    }
    
    func testChannel() {
        let drum = bank!.drum
        XCTAssertEqual(drum.channel, 10)
    }

    func testVelocityDepth() {
        let drum = bank!.drum
        XCTAssertEqual(drum.velocityDepth, 50)
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

final class EffectPatchTests: XCTestCase {
    var bytes = ByteArray()
    var bank: Bank?
    
    // Called before each test method begins
    override func setUp() {
        self.bytes = ByteArray(a401Bytes)
        self.bank = Bank(bytes: self.bytes)
    }
    
    func testEffectType() {
        let effect = bank!.effects[0]
        XCTAssertEqual(effect.effectType, .reverb1)
    }
    
    func testEffectParameters() {
        let effect = bank!.effects[0]
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
        let effect = bank!.effects[0]
        let submix = effect.submixes[0]
        XCTAssertEqual(submix.pan, -7)
        XCTAssertEqual(submix.send1, 45)
        XCTAssertEqual(submix.send2, 0)
    }
    
    func testDescription() {
        let effect = bank!.effects[0]
        
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
