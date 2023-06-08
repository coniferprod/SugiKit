import Foundation

import SyxPack


/// DCA settings.
public struct Amplifier: Codable, Equatable {
    /// DCA envelope.
    public struct Envelope: Codable, Equatable {
        public static let dataSize = 4
        
        public var attack: UInt  // 0~100
        public var decay: UInt  // 0~100
        public var sustain: UInt  // 0~100
        public var release: UInt  // 0~100
        
        /// Initialize an amplifier envelope with default settings.
        public init() {
            attack = 0
            decay = 0
            sustain = 0
            release = 0
        }
        
        /// Initialize an amplifier envelope with parameters.
        public init(attack a: UInt, decay d: UInt, sustain s: UInt, release r: UInt) {
            attack = a
            decay = d
            sustain = s
            release = r
        }

        /// Parse amplifier envelope from MIDI System Exclusive data bytes.
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            
            let attack = UInt(data.next(&offset))
            let decay = UInt(data.next(&offset))
            let sustain = UInt(data.next(&offset))
            let release = UInt(data.next(&offset))

            return .success(Envelope(attack: attack, decay: decay, sustain: sustain, release: release))
        }
    }

    public static let dataSize = 1 + Envelope.dataSize + LevelModulation.dataSize + TimeModulation.dataSize
    
    public var level: UInt  // 0~100
    public var envelope: Envelope
    public var levelModulation: LevelModulation
    public var timeModulation: TimeModulation
    
    /// Initializes an amplifier with default settings.
    public init() {
        level = 100
        envelope = Envelope(attack: 0, decay: 50, sustain: 0, release: 50)
        levelModulation = LevelModulation()
        timeModulation = TimeModulation()
    }

    /// Parse amplifier from MIDI System Exclusive data bytes.
    public static func parse(from data: ByteArray) -> Result<Amplifier, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        
        var temp = Amplifier()
        
        b = data.next(&offset)
        temp.level = UInt(b)

        let envelopeData = data.slice(from: offset, length: Envelope.dataSize)
        switch Envelope.parse(from: envelopeData) {
        case .success(let envelope):
            temp.envelope = envelope
        case .failure(let error):
            return .failure(error)
        }
        offset += Envelope.dataSize
        
        let levelModulationData = data.slice(from: offset, length: LevelModulation.dataSize)
        switch LevelModulation.parse(from: levelModulationData) {
        case .success(let levelModulation):
            temp.levelModulation = levelModulation
        case .failure(let error):
            return .failure(error)
        }
        offset += LevelModulation.dataSize
        
        let timeModulationData = data.slice(from: offset, length: TimeModulation.dataSize)
        switch TimeModulation.parse(from: timeModulationData) {
        case .success(let timeModulation):
            temp.timeModulation = timeModulation
        case .failure(let error):
            return .failure(error)
        }
        offset += TimeModulation.dataSize
        
        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension Amplifier: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
            
        buf.append(Byte(level))
        buf.append(contentsOf: self.envelope.asData())
        buf.append(contentsOf: self.levelModulation.asData())
        buf.append(contentsOf: self.timeModulation.asData())

        return buf
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { Amplifier.dataSize }
}

extension Amplifier.Envelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        [attack, decay, sustain, release].forEach { buf.append(Byte($0)) }
        return buf
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { Amplifier.Envelope.dataSize }
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
