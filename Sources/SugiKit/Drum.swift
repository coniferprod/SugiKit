import Foundation

public struct DrumSource: Codable {
    public var waveNumber: Int
    public var decay: Int
    public var tune: Int
    public var level: Int
    
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
    
    public var submix: SubmixType
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
        b = buffer[offset]
        offset += 1
        let submixValue = Int(b.bitField(start: 4, end: 7))
        submix = SubmixType(index: submixValue)!
        
        source1 = DrumSource()
        source2 = DrumSource()
        
        // S1 wave select MSB
        let s1High = b

        // S2 wave select MSB
        b = buffer[offset]
        offset += 1
        let s2High = b
        
        // S1 wave select LSB
        b = buffer[offset]
        offset += 1
        let s1Low = b
        
        // S2 wave select LSB
        b = buffer[offset]
        offset += 1
        let s2Low = b

        source1.waveNumber = decodeWaveNumber(msb: s1High, lsb: s1Low)
        source2.waveNumber = decodeWaveNumber(msb: s2High, lsb: s2Low)

        // S1 decay
        b = buffer[offset]
        offset += 1
        source1.decay = Int(b)

        // S2 decay
        b = buffer[offset]
        offset += 1
        source2.decay = Int(b)

        // S1 tune
        b = buffer[offset]
        offset += 1
        source1.tune = Int(b)

        // S2 tune
        b = buffer[offset]
        offset += 1
        source2.tune = Int(b)

        // S1 level
        b = buffer[offset]
        offset += 1
        source1.level = Int(b)

        // S2 level
        b = buffer[offset]
        offset += 1
        source2.level = Int(b)

        // last byte is checksum
    }
    
    public func decodeWaveNumber(msb: Byte, lsb: Byte) -> Int {
        let high = msb.bitField(start: 0, end: 1)
        let low = lsb
        let binaryString = high.toBinary() + low.toBinary()
        return Int(binaryString, radix: 2)!
    }

    public func encodeWaveNumber(waveNumber: Int) -> (Byte, Byte) {
        // Encode wave number as two bytes
        let waveNumberString = String(source1.waveNumber, radix: 2).pad(with: "0", toLength: 8)
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

public struct Drum: Codable {
    public static let dataSize = 682
    public static let drumNoteCount = 61

    public var channel: Byte  // store 0...15 as 1...16
    public var volume: Int  // 0~100
    public var velocityDepth: Int  // 0~100
    public var notes: [DrumNote]
    
    public init() {
        channel = 1
        volume = 100
        velocityDepth = 0
        
        notes = [DrumNote]()
        for _ in 0..<Drum.drumNoteCount {
            notes.append(DrumNote())
        }
    }
    
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0

        var data = ByteArray(buffer)
        
        self.channel = data.first!
        offset += 1
        data.removeFirst()

        self.volume = Int(data.first!)
        offset += 1
        data.removeFirst()
        
        self.velocityDepth = Int(data.first!)
        offset += 1
        data.removeFirst()
        
        data.removeFirst(7)  // remove the dummy bytes
        
        notes = [DrumNote]()
        for _ in 0..<Drum.drumNoteCount {
            notes.append(DrumNote(bytes: ByteArray(data.prefix(DrumNote.dataSize))))
            data.removeFirst(DrumNote.dataSize)
        }
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        buf.append(contentsOf: [
            Byte(channel - 1),
            Byte(volume),
            Byte(velocityDepth),
            0, 0, 0, 0, 0, 0  // dummy bytes
        ])

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
