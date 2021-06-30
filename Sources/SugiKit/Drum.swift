import Foundation

public struct DrumSource: Codable {
    public var waveNumber: Int
    public var decay: Int // 0~100
    public var tune: Int // 0~100 / 0~+/50
    public var level: Int // 0~100 (from correction sheet, not 0~99)
    
    public init() {
        waveNumber = 97  // KICK
        decay = 1
        tune = 0
        level = 100
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        // Encode wave number as two bytes
        let waveNumberString = String(waveNumber, radix: 2).pad(with: "0", toLength: 8)
        // First byte is just the top bit
        let highByte = Byte(waveNumberString.prefix(1), radix: 2)!
        // Second byte is all the rest
        let restIndex = waveNumberString.index(after: waveNumberString.startIndex)
        let lowByte = Byte(waveNumberString.suffix(from: restIndex), radix: 2)!
        
        buf.append(contentsOf: [
            highByte,
            lowByte,
            Byte(decay),
            Byte(tune),
            Byte(level)
        ])
        
        return buf
    }
}

/// Represents a note in the drum patch.
public struct DrumNote: Codable {
    public static let dataSize = 11
    
    public var submix: Submix
    public var source1: DrumSource
    public var source2: DrumSource
    
    public init() {
        submix = .a
        source1 = DrumSource()
        source2 = DrumSource()
    }
    
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0

        // Submix / out select is actually bits 4-6 of the first byte
        b = buffer.next(&offset)
        let submixValue = Int(b.bitField(start: 4, end: 7))
        submix = Submix(index: submixValue)!
        
        source1 = DrumSource()
        source2 = DrumSource()
        
        // S1 wave select MSB
        let s1High = b.bitField(start: 0, end: 1)

        // S2 wave select MSB
        b = buffer.next(&offset)
        let s2High = b
        
        // S1 wave select LSB
        b = buffer.next(&offset)
        let s1Low = b
        
        // S2 wave select LSB
        b = buffer.next(&offset)
        let s2Low = b

        source1.waveNumber = decodeWaveNumber(msb: s1High, lsb: s1Low)
        source2.waveNumber = decodeWaveNumber(msb: s2High, lsb: s2Low)

        // S1 decay
        b = buffer.next(&offset)
        source1.decay = Int(b)

        // S2 decay
        b = buffer.next(&offset)
        source2.decay = Int(b)

        // S1 tune
        b = buffer.next(&offset)
        source1.tune = Int(b) - 50

        // S2 tune
        b = buffer.next(&offset)
        source2.tune = Int(b) - 50

        // S1 level
        b = buffer.next(&offset)
        source1.level = Int(b)

        // S2 level
        b = buffer.next(&offset)
        source2.level = Int(b)

        // last byte is checksum
    }
    
    public func decodeWaveNumber(msb: Byte, lsb: Byte) -> Int {
        let binaryString = msb.toBinary() + lsb.toBinary().pad(with: "0", toLength: 7)
        return Int(binaryString, radix: 2)! + 1 // bring into 1~256
    }

    public func encodeWaveNumber(waveNumber: Int) -> (Byte, Byte) {
        let number = waveNumber - 1  // bring into range 0...255
        // Encode wave number as two bytes. First convert the number to binary with eight bits, zero-padded from the left if necessary.
        let waveNumberString = String(number, radix: 2).pad(with: "0", toLength: 8)
        // First byte is just the top bit
        let highByte = Byte(waveNumberString.prefix(1), radix: 2)!
        // Second byte is all the rest
        let restIndex = waveNumberString.index(after: waveNumberString.startIndex)
        let lowByte = Byte(waveNumberString.suffix(from: restIndex), radix: 2)!
        
        return (highByte, lowByte)
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        let (source1WaveHigh, source1WaveLow) = encodeWaveNumber(waveNumber: source1.waveNumber)
        let (source2WaveHigh, source2WaveLow) = encodeWaveNumber(waveNumber: source2.waveNumber)
        buf.append(contentsOf: [
            source1WaveHigh,
            source2WaveHigh,
            source1WaveLow,
            source2WaveLow,
            Byte(source1.decay),
            Byte(source2.decay),
            Byte(source1.tune),
            Byte(source2.tune),
            Byte(source1.level),
            Byte(source2.level)
        ])
                
        return buf
    }
    
    public var systemExclusiveData: ByteArray {
        var buf = ByteArray()
        buf.append(contentsOf: self.data)
        buf.append(checksum(bytes: data))
        return buf
    }
}

public struct DrumCommon: Codable {
    public static let dataSize = 11

    public var channel: Byte  // drm rcv ch, store 0...15 as 1...16
    public var volume: Int  // drm vol, 0~100
    public var velocityDepth: Int  // drm vel depth, 0~100 but actually -50...+50
    public var commonChecksum: Byte

    public init() {
        channel = 1
        volume = 100
        velocityDepth = 0
        commonChecksum = 0x00
    }
    
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0

        b = buffer.next(&offset)
        self.channel = b + 1

        b = buffer.next(&offset)
        self.volume = Int(b)
        
        b = buffer.next(&offset)
        // DRUM velocity depth is actually -50...+50
        self.velocityDepth = Int(b) - 50  // adjust from 0~100
        
        b = buffer.next(&offset)
        self.commonChecksum = b  // save the original checksum from SysEx for now
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        var data = ByteArray()
        data.append(contentsOf: [
            channel - 1,
            Byte(volume),
            Byte(velocityDepth),
            0, 0, 0, 0, 0, 0,  // dummy bytes
        ])
        buf.append(contentsOf: data)
        buf.append(checksum(bytes: data))

        return buf
    }
}

public struct Drum: Codable {
    public static let dataSize = 682
    public static let drumNoteCount = 61

    public var common: DrumCommon
    public var notes: [DrumNote]
    
    public init() {
        common = DrumCommon()
        
        notes = [DrumNote]()
        for _ in 0..<Drum.drumNoteCount {
            notes.append(DrumNote())
        }
    }
    
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0
        
        common = DrumCommon(bytes: buffer.slice(from: offset, length: DrumCommon.dataSize))
        offset += DrumCommon.dataSize
        
        notes = [DrumNote]()
        for i in 0..<Drum.drumNoteCount {
            let noteBytes = buffer.slice(from: offset, length: DrumNote.dataSize)
            notes.append(DrumNote(bytes: noteBytes))
            //print("drum note \(i):\n\(noteBytes.hexDump)")
            offset += DrumNote.dataSize
        }
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        buf.append(contentsOf: self.common.data)
        self.notes.forEach { buf.append(contentsOf: $0.systemExclusiveData) }
        return buf
    }

    public var systemExclusiveData: ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }
}
