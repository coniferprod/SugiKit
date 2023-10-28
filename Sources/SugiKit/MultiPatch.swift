import Foundation

import SyxPack


/// Represents a multi patch.
public class MultiPatch: HashableClass, Identifiable {
    /// Represents one section of a multi patch.
    public struct Section: Equatable {
        /// The data size of this multi section.
        public static let dataSize = 8
        
        public var singlePatchNumber: InstrumentNumber  // 0~63 / A-1 ~ D-16
        public var zone: Zone  // 0~127 / C-2 ~ G8
        public var channel: MIDIChannel  // 0...15 / 1...16
        public var velocitySwitch: VelocitySwitch
        public var isMuted: Bool
        public var submix: Submix
        public var playMode: PlayMode
        public var level: Level  // 0~100
        public var transpose: Transpose  // 0~48 / +/- 24
        public var tune: Depth  // 0~100 / +/- 50
        
        /// Initialize a multi patch section with default settings.
        public init() {
            singlePatchNumber = InstrumentNumber()
            
            zone = Zone()
            zone.high = 0
            zone.low = 127
            
            channel = MIDIChannel(1)
            velocitySwitch = .all
            isMuted = false
            submix = .a
            playMode = .keyboard
            level = Level(100)
            transpose = Transpose()
            tune = Depth()
        }
        
        /// Parse multi patch section from MIDI System Exclusive data bytes.
        /// - Parameter data: The data bytes.
        /// - Returns: A result type with valid `Section` data or an instance of `ParseError`.
        public static func parse(from data: ByteArray) -> Result<Section, ParseError> {
            guard data.count >= Section.dataSize else {
                return .failure(.notEnoughData(data.count, Section.dataSize))
            }
            
            var offset = 0
            var b: Byte = 0x00
            var index = 0  // reused for enumerations

            var temp = Section()  // initialize with defaults, then fill in
            
            b = data.next(&offset)
            temp.singlePatchNumber = InstrumentNumber(Int(b))

            b = data.next(&offset)
            temp.zone = Zone()
            temp.zone.low = Int(b)
            
            b = data.next(&offset)
            temp.zone.high = Int(b)
            
            // channel, velocity switch, and section mute are all in M15
            b = data.next(&offset)

            temp.channel = MIDIChannel(Int(b.bitField(start: 0, end: 4) + 1))

            index = Int(b.bitField(start: 4, end: 6))
            if let vs = VelocitySwitch(index: index) {
                temp.velocitySwitch = vs
            }
            else {
                return .failure(.invalidData(offset))
            }
            
            temp.isMuted = b.isBitSet(6)
            
            // M16: out select and mode
            b = data.next(&offset)

            index = Int(b & 0b00000111)
            if let sm = Submix(index: index) {
                temp.submix = sm
            }
            else {
                return .failure(.invalidData(offset))
            }

            index = Int((b & 0b00011000) >> 3)
            if let mode = PlayMode(index: index) {
                temp.playMode = mode
            }
            else {
                return .failure(.invalidData(offset))
            }

            b = data.next(&offset)
            temp.level = Level(Int(b))
            
            b = data.next(&offset)
            temp.transpose = Transpose(Int(b) - 24)
            
            b = data.next(&offset)
            temp.tune = Depth(Int(b) - 50)

            return .success(temp)
        }
        
        // Gets the SysEx data for the multi patch section.
        private var data: ByteArray {
            var d = ByteArray()
            
            // M12 / M20 etc.
            d.append(Byte(singlePatchNumber.value))
            
            // M13 / M21 etc.
            d.append(Byte(zone.low))
            
            // M14
            d.append(Byte(zone.high))
            
            // M15
            var m15 = Byte(channel.value - 1)
            m15 |= Byte(velocitySwitch.index) << 4
            if isMuted {
                m15.setBit(6)
            }
            d.append(m15)
            
            // M16
            var m16: Byte = Byte(submix.index)
            m16 |= Byte(playMode.index) << 3
            d.append(m16)

            // M17
            d.append(Byte(level.value))
            
            // M18
            d.append(Byte(transpose.value + 24))
            
            // M19
            d.append(Byte(tune.value + 50))
            
            return d
        }
    }

    /// The data size of this multi patch.
    public static let dataSize = 77
    
    /// The number of sections in a multi patch.
    public static let sectionCount = 8

    public var name: PatchName // 10 ASCII characters
    
    public var volume: Level  // 0~100 (from correction sheet, not 0~99)
    public var effect: EffectNumber  // 0~31/1~32
    
    public var sections = [Section]()
    
    /// Initializes a multi patch with default settings.
    public override init() {
        name = PatchName("NewMulti")
        volume = Level(100)
        effect = EffectNumber(1)
        
        sections = Array(repeating: Section(), count: MultiPatch.sectionCount)
    }
        
    /// Parse multi patch data from MIDI System Exclusive data bytes.
    /// - Parameter data: The data bytes.
    /// - Returns: A result type with valid `Multi` data or an instance of `ParseError`.
    public static func parse(from data: ByteArray) -> Result<MultiPatch, ParseError> {
        guard data.count >= MultiPatch.dataSize else {
            return .failure(.notEnoughData(data.count, MultiPatch.dataSize))
        }
        
        var offset = 0
        var b: Byte = 0

        let temp = MultiPatch()  // initialize with defaults, then fill in
        
        let nameData = data.slice(from: offset, length: PatchName.length)
        switch PatchName.parse(from: nameData) {
        case .success(let name):
            temp.name = name
        case .failure(_):
            return .failure(.invalidData(offset))
        }
        offset += PatchName.length

        b = data.next(&offset)
        temp.volume = Level(Int(b))

        b = data.next(&offset)
        temp.effect = EffectNumber(Int(b + 1)) // bring 0~31 to 1~32
        
        // Clear out the section data first!
        temp.sections.removeAll()
        
        for _ in 0 ..< MultiPatch.sectionCount {
            let sectionData = data.slice(from: offset, length: Section.dataSize)
            switch Section.parse(from: sectionData) {
            case .success(let section):
                temp.sections.append(section)
            case .failure(let error):
                return .failure(error)
            }
            offset += Section.dataSize
        }
        
        return .success(temp)
    }

    /// Gets the System Exclusive data for the multi patch.
    private var data: ByteArray {
        var d = ByteArray()
        
        // M0...M9 = name
        d.append(contentsOf: self.name.asData())

        // M10
        d.append(Byte(volume.value))
        
        // M11
        d.append(Byte(effect.value - 1)) // 1~32 to 0~31
        
        // M12 / M20 / M28 / M36 / M44 / M52 / M60 / M68
        for section in sections {
            d.append(contentsOf: section.asData())
        }

        return d
    }
}

// MARK: - SystemExclusiveData

extension MultiPatch: SystemExclusiveData {
    /// Gets the System Exclusive data for the multi with checksum.
    public func asData() -> ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))  // M76
        return buf
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { MultiPatch.dataSize }
}

extension MultiPatch.Section: SystemExclusiveData {
    /// Gets the System Exclusive data for the multi section.
    public func asData() -> ByteArray {
        return self.data
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { MultiPatch.Section.dataSize }
}
