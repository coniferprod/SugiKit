import Foundation

public struct FilterEnvelope: Codable, Equatable {
    public var attack: Int
    public var decay: Int
    public var sustain: Int  // -50~+50, in SysEx 0~100
    public var release: Int
    
    public init() {
        attack = 0
        decay = 0
        sustain = 0
        release = 0
    }

    public init(attack a: Int, decay d: Int, sustain s: Int, release r: Int) {
        attack = a
        decay = d
        sustain = s
        release = r
    }
    
    public var data: Data {
        get {
            var d = Data()
            
            d.append(Byte(attack))
            d.append(Byte(decay))
            d.append(Byte(sustain + 50))
            d.append(Byte(release))

            return d
        }
    }
}

public struct Filter: Codable, Equatable {
    static let dataSize = 14
    
    public var cutoff: Int
    public var resonance: Int
    public var cutoffModulation: LevelModulation
    public var isLfoModulatingCutoff: Bool
    public var envelopeDepth: Int
    public var envelopeVelocityDepth: Int
    public var envelope: FilterEnvelope
    public var timeModulation: TimeModulation
    
    public init() {
        cutoff = 100
        resonance = 0
        cutoffModulation = LevelModulation()
        isLfoModulatingCutoff = false
        envelopeDepth = 0
        envelopeVelocityDepth = 0
        envelope = FilterEnvelope(attack: 0, decay: 50, sustain: 0, release: 50)
        timeModulation = TimeModulation()
    }
    
    public init(d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        offset += 1
        self.cutoff = Int(b)
        
        b = d[offset]
        offset += 1
        self.resonance = Int(b & 0x07)  // resonance is 0...7 also in the UI, even though the SysEx spec says 0~7 means 1~8
        self.isLfoModulatingCutoff = b.isBitSet(3)

        self.cutoffModulation = LevelModulation()
        
        b = d[offset]
        offset += 1
        self.cutoffModulation.velocityDepth = Int(b & 0x7f) - 50

        b = d[offset]
        offset += 1
        self.cutoffModulation.pressureDepth = Int(b & 0x7f) - 50

        b = d[offset]
        offset += 1
        self.cutoffModulation.keyScalingDepth = Int(b & 0x7f) - 50
        
        b = d[offset]
        offset += 1
        self.envelopeDepth = Int(b & 0x7f) - 50

        b = d[offset]
        offset += 1
        self.envelopeVelocityDepth = Int(b & 0x7f) - 50
        
        var e = FilterEnvelope()
        
        b = d[offset]
        offset += 1
        e.attack = Int(b & 0x7f)

        b = d[offset]
        offset += 1
        e.decay = Int(b & 0x7f)

        b = d[offset]
        offset += 1
        e.sustain = Int(b & 0x7f) - 50  // error in manual and SysEx: actually -50~+50, not 0~100

        b = d[offset]
        offset += 1
        e.release = Int(b & 0x7f)
        
        self.envelope = e
        
        self.timeModulation = TimeModulation()
        b = d[offset]
        offset += 1
        self.timeModulation.attackVelocity = Int(b & 0x7f) - 50

        b = d[offset]
        offset += 1
        self.timeModulation.releaseVelocity = Int(b & 0x7f) - 50

        b = d[offset]
        offset += 1
        self.timeModulation.keyScaling = Int(b & 0x7f) - 50
    }
    
    public var data: ByteArray {
        get {
            var d = ByteArray()
            
            d.append(Byte(cutoff))
            
            // s104/105
            var s104 = Byte(resonance)
            if isLfoModulatingCutoff {
                s104.setBit(3)
            }
            d.append(s104)
            
            d.append(contentsOf: cutoffModulation.data)
            
            d.append(Byte(envelopeDepth + 50))
            d.append(Byte(envelopeVelocityDepth + 50))
            
            d.append(contentsOf: envelope.data)
            
            d.append(contentsOf: timeModulation.data)
            
            return d
        }
    }
}
