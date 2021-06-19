import Foundation

/// Represents one section of a multi patch.
public struct MultiSection: Codable {
    public static let dataSize = 8
    
    public var singlePatchNumber: Int  // 0~63 / A-1 ~ D-16
    public var zone: Zone  // 0~127 / C-2 ~G8
    public var channel: Int  // 0...15 / 1...16
    public var velocitySwitch: VelocitySwitch
    public var isMuted: Bool
    public var submix: Submix
    public var playMode: PlayMode
    public var level: Int  // 0~100
    public var transpose: Int  // 0~48 / +/- 24
    public var tune: Int  // 0~100 / +/- 50
    
    public init() {
        singlePatchNumber = 0
        
        zone = Zone()
        zone.high = 0
        zone.low = 127
        
        channel = 1
        velocitySwitch = .all
        isMuted = false
        submix = .a
        playMode = .keyboard
        level = 100
        transpose = 0
        tune = 0
    }
    
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0

        b = buffer.next(&offset)
        singlePatchNumber = Int(b)

        b = buffer.next(&offset)
        zone = Zone()
        zone.low = Int(b)
        
        b = buffer.next(&offset)
        zone.high = Int(b)
        
        // channel, velocity switch, and section mute are all in M15
        b = buffer.next(&offset)

        //print("multi M15 = \(b.toHex(digits: 2))")
        
        //channel = Int(b & 0x1F) + 1
        channel = Int(b.bitField(start: 0, end: 4) + 1)

        //let vs = (b & 0b00110000) >> 4
        let vs = b.bitField(start: 4, end: 6)
        switch vs {
        case 0:
            velocitySwitch = .soft
        case 1:
            velocitySwitch = .loud
        case 2:
            velocitySwitch = .all
        default:
            velocitySwitch = .all
        }
        
        isMuted = b.isBitSet(6)
        
        // M16: out select and mode
        b = buffer.next(&offset)

        let outSelect = b & 0b00000111
        switch outSelect {
        case 1:
            submix = .b
        case 2:
            submix = .c
        case 3:
            submix = .d
        case 4:
            submix = .e
        case 5:
            submix = .f
        case 6:
            submix = .g
        case 7:
            submix = .h
        default:
            submix = .a
        }

        let mode = (b & 0b00011000) >> 3
        switch mode {
        case 1:
            playMode = .midi
        case 2:
            playMode = .mix
        default:
            playMode = .keyboard
        }

        b = buffer.next(&offset)
        level = Int(b)
        
        b = buffer.next(&offset)
        transpose = Int(b) - 24
        
        b = buffer.next(&offset)
        tune = Int(b) - 50
    }
}

/// Represents a multi patch.
public struct MultiPatch: Codable {
    static let dataSize = 77
    static let sectionCount = 8
    static let nameLength = 10

    public var name: String
    public var volume: Int  // 0~99
    public var effect: Int  // 0~31/1~32
    
    public var sections = [MultiSection]()
    
    public init() {
        name = "Multi     "
        volume = 99
        effect = 1
        
        for _ in 0 ..< MultiPatch.sectionCount {
            sections.append(MultiSection())
        }
    }
    
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0

        self.name = String(bytes: buffer.slice(from: offset, length: MultiPatch.nameLength), encoding: .ascii) ?? String(repeating: " ", count: MultiPatch.nameLength)
        offset += MultiPatch.nameLength

        //print("\(self.name):\n\(buffer.hexDump)")
        
        b = buffer.next(&offset)
        self.volume = Int(b)

        b = buffer.next(&offset)
        self.effect = Int(b + 1) // bring 0~31 to 1~32
        
        for _ in 0 ..< MultiPatch.sectionCount {
            let sectionData = buffer.slice(from: offset, length: MultiSection.dataSize)
            sections.append(MultiSection(bytes: sectionData))
            offset += MultiSection.dataSize
        }
    }
    
    public var data: ByteArray {
        return ByteArray(repeating: 0, count: MultiPatch.dataSize)  // TODO: use real data
    }
    
    public var systemExclusiveData: ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }
}
