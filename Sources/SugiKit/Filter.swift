import Foundation

import SyxPack

/// DCF settings.
public struct Filter: Equatable {
    public static func == (lhs: Filter, rhs: Filter) -> Bool {
        return lhs.cutoff == rhs.cutoff
        && lhs.resonance == rhs.resonance
        && lhs.cutoffModulation == rhs.cutoffModulation
        && lhs.isLfoModulatingCutoff == rhs.isLfoModulatingCutoff
        && lhs.envelopeDepth == rhs.envelopeDepth
        && lhs.envelopeVelocityDepth == rhs.envelopeVelocityDepth
        && lhs.envelope == rhs.envelope
        && lhs.timeModulation == rhs.timeModulation
    }
    
    /// DCF envelope.
    public struct Envelope: Equatable {
        public static func == (lhs: Filter.Envelope, rhs: Filter.Envelope) -> Bool {
            return lhs.attack == rhs.attack
            && lhs.decay == rhs.decay
            && lhs.sustain == rhs.sustain
            && lhs.release == rhs.release
        }
        
        public var attack: Level  // 0~100
        public var decay: Level  // 0~100
        public var sustain: Depth  // -50~+50, in SysEx 0~100 (also manual has an error)
        public var release: Level  // 0~100
        
        public init() {
            attack = Level()
            decay = Level()
            sustain = Depth()
            release = Level()
        }

        public init(attack a: Int, decay d: Int, sustain s: Int, release r: Int) {
            attack = Level(a)
            decay = Level(d)
            sustain = Depth(s)
            release = Level(r)
        }
        
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            var temp = Envelope()
            
            b = data.next(&offset)
            temp.attack = Level(Int(b & 0x7f))

            b = data.next(&offset)
            temp.decay = Level(Int(b & 0x7f))

            b = data.next(&offset)
            temp.sustain = Depth(Int(b & 0x7f) - 50)  // error in manual and SysEx: actually -50~+50, not 0~100

            b = data.next(&offset)
            temp.release = Level(Int(b & 0x7f))
            
            return .success(temp)
        }
        
        private var data: ByteArray {
            var buf = ByteArray()
            
            [Byte(attack.value), Byte(decay.value), Byte(sustain.value + 50), Byte(release.value)].forEach {
                buf.append($0)
            }
            
            return buf
        }
        
        public static let dataSize = 4
    }

    public static let dataSize = 14
    
    public var cutoff: Level  // 0~100
    public var resonance: Resonance  // 0~7
    public var cutoffModulation: LevelModulation
    public var isLfoModulatingCutoff: Bool
    public var envelopeDepth: Depth  // -50~+50
    public var envelopeVelocityDepth: Depth // -50~+50
    public var envelope: Envelope
    public var timeModulation: TimeModulation
    
    public init() {
        cutoff = Level(100)
        resonance = Resonance(0)
        cutoffModulation = LevelModulation()
        isLfoModulatingCutoff = false
        envelopeDepth = Depth(0)
        envelopeVelocityDepth = Depth(0)
        envelope = Envelope(attack: 0, decay: 50, sustain: 0, release: 50)
        timeModulation = TimeModulation()
    }
    
    public init(cutoff: Int, resonance: Int, cutoffModulation: LevelModulation, isLfoModulatingCutoff: Bool, envelopeDepth: Int, envelopeVelocityDepth: Int, envelope: Envelope, timeModulation: TimeModulation) {
        self.cutoff = Level(cutoff)
        self.resonance = Resonance(resonance)
        self.cutoffModulation = cutoffModulation
        self.isLfoModulatingCutoff = isLfoModulatingCutoff
        self.envelopeDepth = Depth(envelopeDepth)
        self.envelopeVelocityDepth = Depth(envelopeVelocityDepth)
        self.envelope = envelope
        self.timeModulation = timeModulation
    }
    
    public static func parse(from data: ByteArray) -> Result<Filter, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        
        var temp = Filter()
        
        b = data.next(&offset)
        temp.cutoff = Level(Int(b))
        
        b = data.next(&offset)
        temp.resonance = Resonance(Int(b & 0x07))  // resonance is 0...7 also in the UI, even though the SysEx spec says 0~7 means 1~8
        temp.isLfoModulatingCutoff = b.isBitSet(3)

        let cutoffModulationData = data.slice(from: offset, length: LevelModulation.dataSize)
        switch LevelModulation.parse(from: cutoffModulationData) {
        case .success(let cutoffModulation):
            temp.cutoffModulation = cutoffModulation
        case .failure(let error):
            return .failure(error)
        }
        offset += LevelModulation.dataSize
        
        b = data.next(&offset)
        temp.envelopeDepth = Depth(Int(b & 0x7f) - 50)

        b = data.next(&offset)
        temp.envelopeVelocityDepth = Depth(Int(b & 0x7f) - 50)

        let envelopeData = data.slice(from: offset, length: Envelope.dataSize)
        switch Envelope.parse(from: envelopeData) {
        case .success(let envelope):
            temp.envelope = envelope
        case .failure(let error):
            return .failure(error)
        }
        offset += Envelope.dataSize

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
    
    private var data: ByteArray {
        var buf = ByteArray()
        
        buf.append(Byte(cutoff.value))
        
        // s104/105
        var s104 = Byte(resonance.value)
        if isLfoModulatingCutoff {
            s104.setBit(3)
        }
        buf.append(s104)
        
        buf.append(contentsOf: cutoffModulation.asData())
        buf.append(Byte(envelopeDepth.value + 50))
        buf.append(Byte(envelopeVelocityDepth.value + 50))
        buf.append(contentsOf: envelope.asData())
        buf.append(contentsOf: timeModulation.asData())

        return buf
    }
}

// MARK: - SystemExclusiveData

extension Filter.Envelope: SystemExclusiveData {
    /// Gets the filter envelope data as MIDI System Exclusive bytes.
    public func asData() -> ByteArray {
        return self.data
    }
    
    /// Gets the length of the filter envelope data.
    public var dataLength: Int { Filter.Envelope.dataSize }
}

extension Filter: SystemExclusiveData {
    /// Gets the filter data as MIDI System Exclusive bytes.
    public func asData() -> ByteArray {
        return self.data
    }
    
    /// Gets the length of the filter data.
    public var dataLength: Int { Filter.dataSize }
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
