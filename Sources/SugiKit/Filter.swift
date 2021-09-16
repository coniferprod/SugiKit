import Foundation

public struct Filter: Codable, Equatable {
    public struct Envelope: Codable, Equatable {
        public var attack: UInt  // 0~100
        public var decay: UInt  // 0~100
        public var sustain: Int  // -50~+50, in SysEx 0~100 (also manual has an error)
        public var release: UInt  // 0~100
        
        public init() {
            attack = 0
            decay = 0
            sustain = 0
            release = 0
        }

        public init(attack a: UInt, decay d: UInt, sustain s: Int, release r: UInt) {
            attack = a
            decay = d
            sustain = s
            release = r
        }
        
        public var data: ByteArray {
            var buf = ByteArray()
            
            [Byte(attack), Byte(decay), Byte(sustain + 50), Byte(release)].forEach {
                buf.append($0)
            }
            return buf
        }
    }

    public static let dataSize = 14
    
    public var cutoff: UInt  // 0~100
    public var resonance: UInt  // 0~7
    public var cutoffModulation: LevelModulation
    public var isLfoModulatingCutoff: Bool
    public var envelopeDepth: Int  // -50~+50
    public var envelopeVelocityDepth: Int // -50~+50
    public var envelope: Envelope
    public var timeModulation: TimeModulation
    
    public init() {
        cutoff = 100
        resonance = 0
        cutoffModulation = LevelModulation()
        isLfoModulatingCutoff = false
        envelopeDepth = 0
        envelopeVelocityDepth = 0
        envelope = Envelope(attack: 0, decay: 50, sustain: 0, release: 50)
        timeModulation = TimeModulation()
    }
    
    public init(cutoff: UInt, resonance: UInt, cutoffModulation: LevelModulation, isLfoModulatingCutoff: Bool, envelopeDepth: Int, envelopeVelocityDepth: Int, envelope: Envelope, timeModulation: TimeModulation) {
        self.cutoff = cutoff
        self.resonance = resonance
        self.cutoffModulation = cutoffModulation
        self.isLfoModulatingCutoff = isLfoModulatingCutoff
        self.envelopeDepth = envelopeDepth
        self.envelopeVelocityDepth = envelopeVelocityDepth
        self.envelope = envelope
        self.timeModulation = timeModulation
    }
    
    public init(d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        self.cutoff = UInt(b)
        
        b = d.next(&offset)
        self.resonance = UInt(b & 0x07)  // resonance is 0...7 also in the UI, even though the SysEx spec says 0~7 means 1~8
        self.isLfoModulatingCutoff = b.isBitSet(3)

        self.cutoffModulation = LevelModulation()
        
        b = d.next(&offset)
        self.cutoffModulation.velocityDepth = Int(b & 0x7f) - 50

        b = d.next(&offset)
        self.cutoffModulation.pressureDepth = Int(b & 0x7f) - 50

        b = d.next(&offset)
        self.cutoffModulation.keyScalingDepth = Int(b & 0x7f) - 50
        
        b = d.next(&offset)
        self.envelopeDepth = Int(b & 0x7f) - 50

        b = d.next(&offset)
        self.envelopeVelocityDepth = Int(b & 0x7f) - 50
        
        var e = Envelope()
        
        b = d.next(&offset)
        e.attack = UInt(b & 0x7f)

        b = d.next(&offset)
        e.decay = UInt(b & 0x7f)

        b = d.next(&offset)
        e.sustain = Int(b & 0x7f) - 50  // error in manual and SysEx: actually -50~+50, not 0~100

        b = d.next(&offset)
        e.release = UInt(b & 0x7f)
        
        self.envelope = e
        
        self.timeModulation = TimeModulation()
        b = d.next(&offset)
        self.timeModulation.attackVelocity = Int(b & 0x7f) - 50

        b = d.next(&offset)
        self.timeModulation.releaseVelocity = Int(b & 0x7f) - 50

        b = d.next(&offset)
        self.timeModulation.keyScaling = Int(b & 0x7f) - 50
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        buf.append(Byte(cutoff))
        
        // s104/105
        var s104 = Byte(resonance)
        if isLfoModulatingCutoff {
            s104.setBit(3)
        }
        buf.append(s104)
        
        buf.append(contentsOf: cutoffModulation.data)
        buf.append(Byte(envelopeDepth + 50))
        buf.append(Byte(envelopeVelocityDepth + 50))
        buf.append(contentsOf: envelope.data)
        buf.append(contentsOf: timeModulation.data)

        return buf
    }
}

// MARK: - CustomStringConvertible

extension Filter: CustomStringConvertible {
    public var description: String {
        return "Cutoff=\(self.cutoff) Resonance=\(self.resonance) CutOffMod=\(self.cutoffModulation) LFO=\(self.isLfoModulatingCutoff) Env.Depth=\(self.envelopeDepth) Env.Vel.Depth=\(self.envelopeVelocityDepth) Env=\(self.envelope) TimeMod=\(self.timeModulation)"
    }
}

extension Filter.Envelope: CustomStringConvertible {
    public var description: String {
        return "A=\(self.attack) D=\(self.decay) S=\(self.sustain) R=\(self.release)"
    }
}
