import Foundation

import SyxPack

/// Drum patch.
public struct Drum: Equatable {
    /// Common settings of the drum patch.
    public struct Common: Equatable {
        /// Compares two drum common instances.
        /// - Parameter lhs: the left-hand side
        /// - Parameter rhs: the right-hand side
        /// - Returns: `true` if instances are equal, `false` if not
        public static func == (lhs: Drum.Common, rhs: Drum.Common) -> Bool {
            return lhs.channel == rhs.channel
            && lhs.volume == rhs.volume
            && lhs.velocityDepth == rhs.velocityDepth
            && lhs.commonChecksum == rhs.commonChecksum
        }
        
        /// Data size of drum common settings.
        public static let dataSize = 11

        public var channel: MIDIChannel  // drm rcv ch, store 0...15 as 1...16
        public var volume: Level  // drm vol, 0~100
        public var velocityDepth: Depth  // drm vel depth, -50~+50 (0~100 in SysEx)
        public var commonChecksum: Byte

        /// Initializes the drum patch common settings with default values.
        public init() {
            channel = MIDIChannel(1)
            volume = Level(100)
            velocityDepth = Depth(0)
            commonChecksum = 0x00
        }
        
        /// Parse drum common data from MIDI System Exclusive data bytes.
        /// - Parameter data: The data bytes.
        /// - Returns: A result type with valid `Common` data or an instance of `ParseError`.
        public static func parse(from data: ByteArray) -> Result<Common, ParseError> {
            guard data.count >= Common.dataSize else {
                return .failure(.notEnoughData(data.count, Common.dataSize))
            }
            
            var tempCommon = Common()  // initialize to defaults
            
            var offset = 0
            var b: Byte = 0

            b = data.next(&offset)
            tempCommon.channel = MIDIChannel(Int(b + 1))  // adjust to 1...16

            b = data.next(&offset)
            tempCommon.volume = Level(Int(b))
            
            b = data.next(&offset)
            // DRUM velocity depth is actually -50...+50
            tempCommon.velocityDepth = Depth(Int(b) - 50)  // adjust from 0~100
            
            b = data.next(&offset)
            tempCommon.commonChecksum = b  // save the original checksum from SysEx for now
            
            return .success(tempCommon)
        }
    }

    /// Source for drum patch.
    public struct Source: Equatable {
        /// Compares two drum patch sources.
        public static func == (lhs: Drum.Source, rhs: Drum.Source) -> Bool {
            return lhs.wave == rhs.wave
            && lhs.decay == rhs.decay
            && lhs.tune == rhs.tune
            && lhs.level == rhs.level
        }
        
        /// Data size of this drum source.
        public static let dataSize = 5
        
        public var wave: Wave
        public var decay: Level // 0~100
        public var tune: Depth // -50~+50 (in SysEx 0~100)
        public var level: Level // 0~100 (from correction sheet, not 0~99)
        
        /// Initializes the drum source with default values.
        public init() {
            wave = Wave(number: 97) // "KICK"
            decay = Level(0)
            tune = Depth(0)
            level = Level(100)
        }

        /// Initializes the drum source with the specified values.
        /// - Parameter wave: the wave to use for this drum source
        /// - Parameter decay: the decay time for the wave
        /// - Parameter tune: the tuning of the wave
        /// - Parameter level: the volume level of the wave
        public init(wave: Wave, decay: Int, tune: Int, level: Int) {
            self.wave = wave
            self.decay = Level(decay)
            self.tune = Depth(tune)
            self.level = Level(level)
        }
        
        /// Parse drum source data from MIDI System Exclusive data bytes.
        /// - Parameter data: The data bytes.
        /// - Returns: A result type with a valid `Source` or an instance of `ParseError`.
        public static func parse(from data: ByteArray) -> Result<Source, ParseError> {
            guard 
                data.count >= Source.dataSize
            else {
                return .failure(.notEnoughData(data.count, Source.dataSize))
            }
            
            var tempSource = Source()  // initialize to defaults
            
            // s1 wave select MSB contains the out select in bits 4...6, so mask it off
            let highByte: Byte = data[0] & 0b00000001
            let lowByte = data[1]
            tempSource.wave = Wave(highByte: highByte, lowByte: lowByte)

            tempSource.decay = Level(Int(data[2]))
            tempSource.tune = Depth(Int(data[3]) - 50)
            tempSource.level = Level(Int(data[4]))
            
            return .success(tempSource)
        }
    }

    /// Represents a note in the drum patch.
    public struct Note: Equatable {
        public static let dataSize = 11
        
        public var submix: Submix
        public var source1: Source
        public var source2: Source

        /// Initializes a drum note with default values.
        public init() {
            submix = .a
            source1 = Source()
            source2 = Source()
        }
        
        /// Initializes a drum note with the specified values.
        /// - Parameter submix: the submix settings
        /// - Parameter source1: source 1 settings
        /// - Parameter source2: source 2 settings
        public init(submix: Submix, source1: Source, source2: Source) {
            self.submix = submix
            self.source1 = source1
            self.source2 = source2
        }
        
        private var data: ByteArray {
            // Interleave the bytes for S1 and S2
            var buf = zip(source1.asData(), source2.asData()).flatMap({ [$0, $1] })
            
            // Inject the output select into the very first byte:
            buf[0] |= Byte(submix.index << 4)
            
            return buf
        }
        
        /// Parse note data from MIDI System Exclusive data bytes.
        /// - Parameter data: The data bytes.
        /// - Returns: A result type with valid `Note` data or an instance of `ParseError`.
        public static func parse(from data: ByteArray) -> Result<Note, ParseError> {
            guard 
                data.count >= Note.dataSize
            else {
                return .failure(.notEnoughData(data.count, Note.dataSize))
            }
            
            var tempNote = Note()
            
            // Submix / out select is actually bits 4-6 of the first byte
            let submixValue = Int(data[0].bitField(start: 4, end: 7))
            tempNote.submix = Submix(index: submixValue)!
            
            let sourceBytes = ByteArray(data[0...9])  // everything but the checksum
            
            // Split the alternating bytes into their own arrays for S1 and S2
            let source1Bytes = sourceBytes.everyNthByte(n: 2, start: 0)
            let source2Bytes = sourceBytes.everyNthByte(n: 2, start: 1)
                
            // Construct the drum sources from the raw bytes
            switch Source.parse(from: source1Bytes) {
            case .success(let source):
                tempNote.source1 = source
            case .failure(let error):
                return .failure(error)
            }
            
            switch Source.parse(from: source2Bytes) {
            case .success(let source):
                tempNote.source2 = source
            case .failure(let error):
                return .failure(error)
            }
            
            return .success(tempNote)
        }
    }
    
    public static let dataSize = 682
    public static let noteCount = 61

    public var common: Common
    public var notes: [Note]
    
    /// Initializes the drum patch with default settings.
    public init() {
        common = Common()        
        notes = Array(repeating: Note(), count: Drum.noteCount)
    }
    
    /// Parse drum data from MIDI System Exclusive data bytes.
    /// - Parameter data: The data bytes.
    /// - Returns: A result type with valid `Drum` data or an instance of `ParseError`.
    public static func parse(from data: ByteArray) -> Result<Drum, ParseError> {
        guard 
            data.count >= Drum.dataSize
        else {
            return .failure(.notEnoughData(data.count, Drum.dataSize))
        }
        
        var temp = Drum()  // everything initialized to default values
        
        var offset = 0
        var size = Common.dataSize
        
        switch Common.parse(from: data.slice(from: offset, length: size)) {
            case .success(let common):
                temp.common = common
            case .failure(let error):
                return .failure(error)
        }
        
        offset += size
        
        size = Note.dataSize
        var tempNotes = [Note]()
        for _ in 0..<Drum.noteCount {
            let noteBytes = data.slice(from: offset, length: size)
            switch Note.parse(from: noteBytes) {
            case .success(let note):
                tempNotes.append(note)
            case .failure(let error):
                return .failure(error)
            }
            offset += size
        }
        
        temp.notes = tempNotes
        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension Drum: SystemExclusiveData {
    /// Gets the drum patch System Exclusive data.
    /// - Returns: a byte array with the data
    public func asData() -> ByteArray {
        var buf = ByteArray()
        
        buf.append(contentsOf: self.common.asData())  // includes the common checksum
        
        // The SysEx data for each note has its own checksum
        self.notes.forEach { buf.append(contentsOf: $0.asData()) }

        return buf
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { Drum.dataSize }
}

extension Drum.Common: SystemExclusiveData {
    /// Gets the System Exclusive data for the drum common settings.
    /// - Returns: a byte array with the data
    public func asData() -> ByteArray {
        var buf = ByteArray()
        
        let data: ByteArray = [
            Byte(channel.value - 1),  // adjust to 0...15
            Byte(volume.value),
            Byte(velocityDepth.value),
            0, 0, 0, 0, 0, 0, 0 // seven dummy bytes (d03...d09)
        ]
        
        buf.append(contentsOf: data)
        buf.append(checksum(bytes: data))
        return buf
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { Drum.Common.dataSize }
}

extension Drum.Source: SystemExclusiveData {
    /// Gets the System Exclusive data for the drum source settings.
    /// - Returns: a byte array with the data
    public func asData() -> ByteArray {
        var buf = ByteArray()

        buf.append(contentsOf: self.wave.asData())
        buf.append(contentsOf: [
            Byte(decay.value),
            Byte(tune.value + 50),
            Byte(level.value)
        ])
        
        return buf
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { Drum.Source.dataSize }
}

extension Drum.Note: SystemExclusiveData {
    /// Gets the System Exclusive data for the drum note.
    /// - Returns: a byte array with the data
    public func asData() -> ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { Drum.Note.dataSize }
}
