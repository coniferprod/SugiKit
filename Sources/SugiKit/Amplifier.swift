import Foundation

import SyxPack


/// DCA settings.
public struct Amplifier: Codable, Equatable {
    /// DCA envelope.
    public struct Envelope: Codable, Equatable {
        public var attack: UInt  // 0~100
        public var decay: UInt  // 0~100
        public var sustain: UInt  // 0~100
        public var release: UInt  // 0~100
        
        public init() {
            attack = 0
            decay = 0
            sustain = 0
            release = 0
        }
        
        public init(attack a: UInt, decay d: UInt, sustain s: UInt, release r: UInt) {
            attack = a
            decay = d
            sustain = s
            release = r
        }
    }

    static let dataSize = 11
    
    public var level: UInt  // 0~100
    public var envelope: Envelope
    public var levelModulation: LevelModulation
    public var timeModulation: TimeModulation
    
    public init() {
        level = 100
        envelope = Envelope(attack: 0, decay: 50, sustain: 0, release: 50)
        levelModulation = LevelModulation()
        timeModulation = TimeModulation()
    }
    
    public init(bytes buffer: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = buffer.next(&offset)
        self.level = UInt(b)

        var e = Envelope()
        
        b = buffer.next(&offset)
        e.attack = UInt(b)
        
        b = buffer.next(&offset)
        e.decay = UInt(b)
        
        b = buffer.next(&offset)
        e.sustain = UInt(b)
        
        b = buffer.next(&offset)
        e.release = UInt(b)
    
        self.envelope = e
        
        //
        // Depth values come in as 0...100,
        // they need to be scaled to -50...50.
        //

        self.levelModulation = LevelModulation()

        b = buffer.next(&offset)
        self.levelModulation.velocityDepth = Int(b) - 50

        b = buffer.next(&offset)
        self.levelModulation.pressureDepth = Int(b) - 50
        
        b = buffer.next(&offset)
        self.levelModulation.keyScalingDepth = Int(b) - 50
        
        self.timeModulation = TimeModulation()

        b = buffer.next(&offset)
        self.timeModulation.attackVelocity = Int(b) - 50
        
        b = buffer.next(&offset)
        self.timeModulation.releaseVelocity = Int(b) - 50

        b = buffer.next(&offset)
        self.timeModulation.keyScaling = Int(b) - 50
    }
}

// MARK: - SystemExclusiveData

extension Amplifier: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
            
        buf.append(Byte(level))
        buf.append(contentsOf: self.envelope.asData())
        buf.append(contentsOf: self.levelModulation.data)
        buf.append(contentsOf: self.timeModulation.data)

        return buf
    }
}

extension Amplifier.Envelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        [attack, decay, sustain, release].forEach { buf.append(Byte($0)) }
        return buf
    }
}

// MARK: - CustomStringConvertible

extension Amplifier: CustomStringConvertible {
    public var description: String {
        return "Env=\(self.envelope) LevelMod=\(self.levelModulation) TimeMod=\(self.timeModulation)"
    }
}

extension Amplifier.Envelope: CustomStringConvertible {
    public var description: String {
        return "A=\(attack) D=\(decay) S=\(sustain) R=\(release)"
    }
}
