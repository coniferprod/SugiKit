import Foundation

public struct AmplifierEnvelope: Codable, Equatable {
    public var attack: Int
    public var decay: Int
    public var sustain: Int
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
    
    public var data: ByteArray {
        var buf = ByteArray()
        [attack, decay, sustain, release].forEach { buf.append(Byte($0)) }
        return buf
    }
}

public struct Amplifier: Codable, Equatable {
    static let dataSize = 11
    
    public var level: Int
    public var envelope: AmplifierEnvelope
    public var levelModulation: LevelModulation
    public var timeModulation: TimeModulation
    
    public init() {
        level = 100
        envelope = AmplifierEnvelope(attack: 0, decay: 50, sustain: 0, release: 50)
        levelModulation = LevelModulation()
        timeModulation = TimeModulation()
    }
    
    public init(d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        self.level = Int(b)

        var e = AmplifierEnvelope()
        
        b = d.next(&offset)
        e.attack = Int(b)
        
        b = d.next(&offset)
        e.decay = Int(b)
        
        b = d.next(&offset)
        e.sustain = Int(b)
        
        b = d.next(&offset)
        e.release = Int(b)
    
        self.envelope = e
        
        //
        // Depth values come in as 0...100,
        // they need to be scaled to -50...50.
        //

        self.levelModulation = LevelModulation()

        b = d.next(&offset)
        self.levelModulation.velocityDepth = Int(b) - 50

        b = d.next(&offset)
        self.levelModulation.pressureDepth = Int(b) - 50
        
        b = d.next(&offset)
        self.levelModulation.keyScalingDepth = Int(b) - 50
        
        self.timeModulation = TimeModulation()

        b = d.next(&offset)
        self.timeModulation.attackVelocity = Int(b) - 50
        
        b = d.next(&offset)
        self.timeModulation.releaseVelocity = Int(b) - 50

        b = d.next(&offset)
        self.timeModulation.keyScaling = Int(b) - 50
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
            
        buf.append(Byte(level))
        buf.append(contentsOf: self.envelope.data)
        buf.append(contentsOf: self.levelModulation.data)
        buf.append(contentsOf: self.timeModulation.data)

        return buf
    }
}
