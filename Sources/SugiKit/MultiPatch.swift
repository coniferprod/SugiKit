import Foundation

/// Represents one section of a multi patch.
public struct MultiSection: Codable {
    public static let dataSize = 8
    
    public var singlePatchNumber: Int  // 0~63 / A-1 ~ D-16
    public var zone: ZoneType  // 0~127 / C-2 ~G8
    public var channel: Int  // 0...15 / 1...16
    public var velocitySwitch: VelocitySwitchType
    public var isMuted: Bool
    public var submix: SubmixType
    public var playMode: PlayModeType
    public var level: Int  // 0~100
    public var transpose: Int  // 0~48 / +/- 24
    public var tune: Int  // 0~100 / +/- 50
    
    public init() {
        singlePatchNumber = 0
        
        zone = ZoneType()
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
        var data = ByteArray(buffer)

        singlePatchNumber = Int(data.first!)
        offset += 1
        data.removeFirst()

        zone = ZoneType()
        zone.low = Int(data[0])
        zone.high = Int(data[1])
        data.removeFirst(2)
        offset += 2

        b = data.first! & 0x1f
        channel = Int(b) + 1
        offset += 1
        data.removeFirst()
        let vs = (b & 0b00110000) >> 4
        switch vs {
        case 1:
            velocitySwitch = .soft
        case 2:
            velocitySwitch = .loud
        default:
            velocitySwitch = .all
        }
        
        isMuted = b.isBitSet(6)
        
        b = data.first!
        offset += 1
        data.removeFirst()
        let os = b & 0b00000111
        switch os {
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

        level = Int(data.first!)
        offset += 1
        data.removeFirst()

        transpose = Int(data.first!) - 24
        offset += 1
        data.removeFirst()

        tune = Int(data.first!) - 50
        offset += 1
    }
    
    public init(_ d: Data) {
        var offset: Int = 0
        var b: Byte = 0

        b = d[offset]
        offset += 1
        singlePatchNumber = Int(b)
        
        b = d[offset]
        offset += 1
        zone = ZoneType()
        zone.low = Int(b)
        
        b = d[offset]
        offset += 1
        zone.high = Int(b)
        
        b = d[offset]
        offset += 1
        
        channel = Int(b & 0x1F) + 1
        let vs = (b & 0b00110000) >> 4
        if vs == 0 {
            velocitySwitch = .all
        }
        else if vs == 1 {
            velocitySwitch = .soft
        }
        else if vs == 2 {
            velocitySwitch = .loud
        }
        else {
            velocitySwitch = .all
        }
        
        isMuted = b.isBitSet(6)
        
        b = d[offset]
        offset += 1
        let os = (b & 0b00000111)
        if os == 0 {
            submix = .a
        }
        else if os == 1 {
            submix = .b
        }
        else if os == 2 {
            submix = .c
        }
        else if os == 3 {
            submix = .d
        }
        else if os == 4 {
            submix = .e
        }
        else if os == 5 {
            submix = .f
        }
        else if os == 6 {
            submix = .g
        }
        else if os == 7 {
            submix = .h
        }
        else {
            submix = .a
        }
        
        let mode = (b & 0b00011000) >> 3
        if mode == 0 {
            playMode = .keyboard
        }
        else if mode == 1 {
            playMode = .midi
        }
        else if mode == 2 {
            playMode = .mix
        }
        else {
            playMode = .keyboard
        }
        
        b = d[offset]
        offset += 1
        level = Int(b)
        
        b = d[offset]
        offset += 1
        transpose = Int(b) - 24
        
        b = d[offset]
        offset += 1
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

        var data = ByteArray(buffer)
        
        self.name = String(bytes: data[..<MultiPatch.nameLength], encoding: .ascii) ?? String(repeating: " ", count: MultiPatch.nameLength)
        offset += MultiPatch.nameLength

        self.volume = Int(data.first!)
        offset += 1
        data.removeFirst()

        self.effect = Int(data.first! + 1) // bring 0~31 to 1~32
        offset += 1
        data.removeFirst()
        
        for _ in 0 ..< MultiPatch.sectionCount {
            let sectionData = ByteArray(data[..<MultiSection.dataSize])
            sections.append(MultiSection(bytes: sectionData))
            data.removeFirst(MultiSection.dataSize)
            offset += MultiSection.dataSize
        }
    }
    
    public init(_ d: Data) {
        var offset: Int = 0
        var b: Byte = 0
        
        self.name = String(data: d.subdata(in: offset ..< offset + MultiPatch.nameLength), encoding: .ascii) ?? ""
        offset += MultiPatch.nameLength

        b = d[offset]
        offset += 1
        self.volume = Int(b)
        
        b = d[offset]
        offset += 1
        self.effect = Int(b + 1)  // bring 0~31 to 1~32
        
        for _ in 0 ..< MultiPatch.sectionCount {
            sections.append(MultiSection(d.subdata(in: offset ..< offset + MultiSection.dataSize)))
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
