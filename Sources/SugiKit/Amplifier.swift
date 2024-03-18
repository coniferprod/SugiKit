import Foundation

import SyxPack


/// DCA settings.
public struct Amplifier: Equatable {
    /// DCA envelope.
    public struct Envelope: Equatable {
        /// Data size in bytes
        public static let dataSize = 4
        
        public var attack: Level  // 0~100
        public var decay: Level  // 0~100
        public var sustain: Level  // 0~100
        public var release: Level  // 0~100
        
        /// Initialize an amplifier envelope with default settings.
        public init() {
            attack = Level()
            decay = Level()
            sustain = Level()
            release = Level()
        }
        
        /// Initialize an amplifier envelope with raw Int parameters.
        public init(attack a: Int, decay d: Int, sustain s: Int, release r: Int) {
            attack = Level(a)
            decay = Level(d)
            sustain = Level(s)
            release = Level(r)
        }
        
        /// Initializes an amplifier envelope with Level parameters.
        public init(attack a: Level, decay d: Level, sustain s: Level, release r: Level) {
            attack = a
            decay = d
            sustain = s
            release = r
        }

        /// Parse amplifier envelope from MIDI System Exclusive data bytes.
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            
            let attack = Int(data.next(&offset))
            let decay = Int(data.next(&offset))
            let sustain = Int(data.next(&offset))
            let release = Int(data.next(&offset))

            return .success(Envelope(attack: attack, decay: decay, sustain: sustain, release: release))
        }
        
        /// Compares two `Envelope` instances.
        public static func == (lhs: Amplifier.Envelope, rhs: Amplifier.Envelope) -> Bool {
            return lhs.attack == rhs.attack
                && lhs.decay == rhs.decay
                && lhs.sustain == rhs.sustain
                && lhs.release == rhs.release
        }
    }

    /// DCA SysEx data size
    public static let dataSize = 1 + Envelope.dataSize + LevelModulation.dataSize + TimeModulation.dataSize
    
    public var level: Level  // 0~100
    public var envelope: Envelope
    public var levelModulation: LevelModulation
    public var timeModulation: TimeModulation
    
    /// Initializes an amplifier with default settings.
    public init() {
        level = Level(100)
        envelope = Envelope(attack: 0, decay: 50, sustain: 0, release: 50)
        levelModulation = LevelModulation()
        timeModulation = TimeModulation()
    }

    /// Parse amplifier from MIDI System Exclusive data bytes.
    public static func parse(from data: ByteArray) -> Result<Amplifier, ParseError> {
        var offset: Int = 0
        var size: Int = 0
        var b: Byte = 0
        
        var temp = Amplifier()
        
        b = data.next(&offset)
        temp.level = Level(Int(b))

        size = Envelope.dataSize
        let envelopeData = data.slice(from: offset, length: size)
        switch Envelope.parse(from: envelopeData) {
        case .success(let envelope):
            temp.envelope = envelope
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = LevelModulation.dataSize
        let levelModulationData = data.slice(from: offset, length: size)
        switch LevelModulation.parse(from: levelModulationData) {
        case .success(let levelModulation):
            temp.levelModulation = levelModulation
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = TimeModulation.dataSize
        let timeModulationData = data.slice(from: offset, length: size)
        switch TimeModulation.parse(from: timeModulationData) {
        case .success(let timeModulation):
            temp.timeModulation = timeModulation
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        return .success(temp)
    }
    
    /// Compares two `Amplifier` instances.
    public static func == (lhs: Amplifier, rhs: Amplifier) -> Bool {
        return lhs.level == rhs.level
            && lhs.envelope == rhs.envelope
            && lhs.levelModulation == rhs.levelModulation
            && lhs.timeModulation == rhs.timeModulation
    }
}

// MARK: - SystemExclusiveData

extension Amplifier: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this DCA.
    public func asData() -> ByteArray {
        var buf = ByteArray()
            
        buf.append(Byte(level.value))
        buf.append(contentsOf: self.envelope.asData())
        buf.append(contentsOf: self.levelModulation.asData())
        buf.append(contentsOf: self.timeModulation.asData())

        return buf
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { Amplifier.dataSize }
}

extension Amplifier.Envelope: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this DCA envelope.
    public func asData() -> ByteArray {
        var buf = ByteArray()
        [attack, decay, sustain, release].forEach { buf.append(Byte($0.value)) }
        return buf
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { Amplifier.Envelope.dataSize }
}

// MARK: - CustomStringConvertible

extension Amplifier: CustomStringConvertible {
    /// Printable description of this DCA.
    public var description: String {
        return "Env=\(self.envelope) LevelMod=\(self.levelModulation) TimeMod=\(self.timeModulation)"
    }
}

extension Amplifier.Envelope: CustomStringConvertible {
    /// Printable description of this DCA envelope.
    public var description: String {
        return "A=\(attack) D=\(decay) S=\(sustain) R=\(release)"
    }
}
