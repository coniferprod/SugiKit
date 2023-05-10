import Foundation

import SyxPack

/// Drum patch.
public struct Drum: Codable, Equatable {
    /// Common settings of the drum patch.
    public struct Common: Codable, Equatable {
        public static let dataSize = 11

        public var channel: Byte  // drm rcv ch, store 0...15 as 1...16
        public var volume: UInt  // drm vol, 0~100
        public var velocityDepth: Int  // drm vel depth, -50~+50 (0~100 in SysEx)
        public var commonChecksum: Byte

        /// Initializes the drum patch common settings with default values.
        public init() {
            channel = 1
            volume = 100
            velocityDepth = 0
            commonChecksum = 0x00
        }
        
        public var data: ByteArray {
            return [
                channel - 1,
                Byte(volume),
                Byte(velocityDepth),
                0, 0, 0, 0, 0, 0, 0 // seven dummy bytes (d03...d09)
            ]
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
            tempCommon.channel = b + 1

            b = data.next(&offset)
            tempCommon.volume = UInt(b)
            
            b = data.next(&offset)
            // DRUM velocity depth is actually -50...+50
            tempCommon.velocityDepth = Int(b) - 50  // adjust from 0~100
            
            b = data.next(&offset)
            tempCommon.commonChecksum = b  // save the original checksum from SysEx for now
            
            return .success(tempCommon)
        }
    }

    /// Source for drum patch.
    public struct Source: Codable, Equatable {
        public static let dataSize = 5
        
        public var wave: Wave
        public var decay: UInt // 0~100
        public var tune: Int // -50~+50 (in SysEx 0~100)
        public var level: UInt // 0~100 (from correction sheet, not 0~99)
        
        /// Initializes the drum source with default values.
        public init() {
            wave = Wave(number: 97) // "KICK"
            decay = 0
            tune = 0
            level = 100
        }
        
        public init(wave: Wave, decay: UInt, tune: Int, level: UInt) {
            self.wave = wave
            self.decay = decay
            self.tune = tune
            self.level = level
        }
        
        public var data: ByteArray {
            var buf = ByteArray()
            
            buf.append(contentsOf: self.wave.asData())
            
            buf.append(contentsOf: [
                Byte(decay),
                Byte(tune + 50),
                Byte(level)
            ])
            
            return buf
        }
        
        /// Parse drum source data from MIDI System Exclusive data bytes.
        /// - Parameter data: The data bytes.
        /// - Returns: A result type with a valid `Source` or an instance of `ParseError`.
        public static func parse(from data: ByteArray) -> Result<Source, ParseError> {
            guard data.count >= Source.dataSize else {
                return .failure(.notEnoughData(data.count, Source.dataSize))
            }
            
            var tempSource = Source()  // initialize to defaults
            
            // s1 wave select MSB contains the out select in bits 4...6, so mask it off
            let highByte: Byte = data[0] & 0b00000001
            let lowByte = data[1]
            tempSource.wave = Wave(highByte: highByte, lowByte: lowByte)

            tempSource.decay = UInt(data[2])
            tempSource.tune = Int(data[3]) - 50
            tempSource.level = UInt(data[4])
            
            return .success(tempSource)
        }
    }

    /// Represents a note in the drum patch.
    public struct Note: Codable, Equatable {
        public static let dataSize = 11
        
        public var submix: Submix
        public var source1: Source
        public var source2: Source
        
        public init() {
            submix = .a
            source1 = Source()
            source2 = Source()
        }
        
        public init(submix: Submix, source1: Source, source2: Source) {
            self.submix = submix
            self.source1 = source1
            self.source2 = source2
        }
        
        public var data: ByteArray {
            // Interleave the bytes for S1 and S2
            var buf = zip(source1.data, source2.data).flatMap({ [$0, $1] })
            
            // Inject the output select into the very first byte:
            buf[0] |= Byte(submix.index << 4)
            
            return buf
        }
        
        /// Parse note data from MIDI System Exclusive data bytes.
        /// - Parameter data: The data bytes.
        /// - Returns: A result type with valid `Note` data or an instance of `ParseError`.
        public static func parse(from data: ByteArray) -> Result<Note, ParseError> {
            guard data.count >= Note.dataSize else {
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
            
/*
            // Compare calculated checksum to what is in the last byte of SysEx data:
            let sum = checksum(bytes: tempNote.data)
            if sum != data[10] {
                return .failure(.badChecksum(sum, data[10]))
            }
  */
            return .success(tempNote)
        }
    }
    
    public static let dataSize = 682
    public static let noteCount = 61

    public var common: Common
    public var notes: [Note]
    
    public init() {
        common = Common()        
        notes = Array(repeating: Note(), count: Drum.noteCount)
    }
    
    /// Parse drum data from MIDI System Exclusive data bytes.
    /// - Parameter data: The data bytes.
    /// - Returns: A result type with valid `Drum` data or an instance of `ParseError`.
    public static func parse(from data: ByteArray) -> Result<Drum, ParseError> {
        guard data.count >= Drum.dataSize else {
            return .failure(.notEnoughData(data.count, Drum.dataSize))
        }
        
        var temp = Drum()  // everything initialized to default values
        
        var offset = 0
        
        switch Common.parse(from: data.slice(from: offset, length: Common.dataSize)) {
            case .success(let common):
                temp.common = common
            case .failure(let error):
                return .failure(error)
        }
        
        offset += Common.dataSize

        var tempNotes = [Note]()
        for _ in 0..<Drum.noteCount {
            let noteBytes = data.slice(from: offset, length: Note.dataSize)
            switch Note.parse(from: noteBytes) {
            case .success(let note):
                tempNotes.append(note)
            case .failure(let error):
                return .failure(error)
            }
            offset += Note.dataSize
        }
        
        temp.notes = tempNotes
        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension Drum: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        
        buf.append(contentsOf: self.common.asData())  // includes the common checksum
        
        // The SysEx data for each note has its own checksum
        self.notes.forEach { buf.append(contentsOf: $0.asData()) }

        return buf
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { Drum.dataSize }
}

extension Drum.Common: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { Drum.Common.dataSize }
}

extension Drum.Note: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { Drum.Note.dataSize }
}
