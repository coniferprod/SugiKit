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
        get {
            var d = ByteArray()
            [attack, decay, sustain, release].forEach { d.append(Byte($0)) }
            return d
        }
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
        
        envelope = AmplifierEnvelope()
        envelope.attack = 0
        envelope.decay = 50
        envelope.sustain = 0
        envelope.release = 50

        levelModulation = LevelModulation()
        levelModulation.velocityDepth = 0
        levelModulation.pressureDepth = 0
        levelModulation.keyScalingDepth = 0

        timeModulation = TimeModulation()
        timeModulation.attackVelocity = 0
        timeModulation.releaseVelocity = 0
        timeModulation.keyScaling = 0
    }
    
    public init(d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        offset += 1
        self.level = Int(b)

        var e = AmplifierEnvelope()
        
        b = d[offset]
        offset += 1
        e.attack = Int(b)
        
        b = d[offset]
        offset += 1
        e.decay = Int(b)
        
        b = d[offset]
        offset += 1
        e.sustain = Int(b)
        
        b = d[offset]
        offset += 1
        e.release = Int(b)
    
        self.envelope = e
        
        //
        // Depth values come in as 0...100,
        // they need to be scaled to -50...50.
        //

        self.levelModulation = LevelModulation()

        b = d[offset]
        offset += 1
        self.levelModulation.velocityDepth = Int(b) - 50

        b = d[offset]
        offset += 1
        self.levelModulation.pressureDepth = Int(b) - 50
        
        b = d[offset]
        offset += 1
        self.levelModulation.keyScalingDepth = Int(b) - 50
        
        self.timeModulation = TimeModulation()

        b = d[offset]
        offset += 1
        self.timeModulation.attackVelocity = Int(b) - 50
        
        b = d[offset]
        offset += 1
        self.timeModulation.releaseVelocity = Int(b) - 50

        b = d[offset]
        offset += 1
        self.timeModulation.keyScaling = Int(b) - 50
    }
    
    public var data: Data {
        get {
            var d = Data()
            
            d.append(Byte(level))
            d.append(contentsOf: self.envelope.data)
            d.append(self.levelModulation.data)
            d.append(self.timeModulation.data)

            return d
        }
    }
}
