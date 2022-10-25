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
        
        /// Initializes the drum patch common settings from MIDI System Exclusive data bytes.
        public init(bytes buffer: ByteArray) {
            var offset = 0
            var b: Byte = 0

            b = buffer.next(&offset)
            self.channel = b + 1

            b = buffer.next(&offset)
            self.volume = UInt(b)
            
            b = buffer.next(&offset)
            // DRUM velocity depth is actually -50...+50
            self.velocityDepth = Int(b) - 50  // adjust from 0~100
            
            b = buffer.next(&offset)
            self.commonChecksum = b  // save the original checksum from SysEx for now
        }
        
        public var data: ByteArray {
            return [
                channel - 1,
                Byte(volume),
                Byte(velocityDepth),
                0, 0, 0, 0, 0, 0, 0 // seven dummy bytes (d03...d09)
            ]
        }
    }

    /// Source for drum patch.
    public struct Source: Codable, Equatable {
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
        
        /// Initializes the drum source from MIDI System Exclusive data bytes.
        public init(bytes buffer: ByteArray) {
            // s1 wave select MSB contains the out select in bits 4...6, so mask it off
            let highByte: Byte = buffer[0] & 0b00000001
            let lowByte = buffer[1]
            wave = Wave(highByte: highByte, lowByte: lowByte)

            decay = UInt(buffer[2])
            tune = Int(buffer[3]) - 50
            level = UInt(buffer[4])
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
    }

    /// Represents a note in the drum patch.
    public struct Note: Codable, Equatable {
        public static let dataSize = 11
        
        public var submix: Submix
        public var source1: Source
        public var source2: Source
        
        public var noteChecksum: Byte
        
        public init() {
            submix = .a
            source1 = Source()
            source2 = Source()
            noteChecksum = 0x00
        }
        
        public init(bytes buffer: ByteArray) {
            // Submix / out select is actually bits 4-6 of the first byte
            let submixValue = Int(buffer[0].bitField(start: 4, end: 7))
            submix = Submix(index: submixValue)!
            
            let sourceBytes = ByteArray(buffer[0...9])  // everything but the checksum
            
            // Split the alternating bytes into their own arrays for S1 and S2
            let source1Bytes = sourceBytes.everyNthByte(n: 2, start: 0)
            let source2Bytes = sourceBytes.everyNthByte(n: 2, start: 1)
                
            // Construct the drum sources from the raw bytes
            source1 = Source(bytes: source1Bytes)
            source2 = Source(bytes: source2Bytes)
            
            // last byte is checksum, we just save it (must be recalculated when generating SysEx)
            noteChecksum = buffer[10]
        }
        
        public var data: ByteArray {
            // Interleave the bytes for S1 and S2
            var buf = zip(source1.data, source2.data).flatMap({ [$0, $1] })
            
            // Inject the output select into the very first byte:
            buf[0] |= Byte(submix.index << 4)
            
            return buf
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
    
    public init(bytes buffer: ByteArray) {
        var offset = 0
        
        common = Common(bytes: buffer.slice(from: offset, length: Common.dataSize))
        offset += Common.dataSize
        
        notes = [Note]()
        for _ in 0..<Drum.noteCount {
            let noteBytes = buffer.slice(from: offset, length: Note.dataSize)
            notes.append(Note(bytes: noteBytes))
            //print("drum note \(i):\n\(noteBytes.hexDump)")
            offset += Note.dataSize
        }
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
}

extension Drum.Common: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }
}

extension Drum.Note: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }
}
