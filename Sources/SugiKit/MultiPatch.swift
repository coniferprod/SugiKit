import Foundation

import SyxPack


/// Represents a multi patch.
public class MultiPatch: HashableClass, Codable, Identifiable {
    /// Represents one section of a multi patch.
    public struct Section: Codable, Equatable {
        public static let dataSize = 8
        
        public var singlePatchNumber: Int  // 0~63 / A-1 ~ D-16
        public var zone: Zone  // 0~127 / C-2 ~G8
        public var channel: Byte  // 0...15 / 1...16
        public var velocitySwitch: VelocitySwitch
        public var isMuted: Bool
        public var submix: Submix
        public var playMode: PlayMode
        public var level: Int  // 0~100
        public var transpose: Int  // 0~48 / +/- 24
        public var tune: Int  // 0~100 / +/- 50
        
        /// Initializes a multi patch section with default settings.
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
        
        /// Initializes a multi patch section from System Exclusive data bytes.
        public init(bytes buffer: ByteArray) {
            var offset = 0
            var b: Byte = 0x00
            var index = 0  // reused for enumerations

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
            
            channel = b.bitField(start: 0, end: 4) + 1

            index = Int(b.bitField(start: 4, end: 6))
            if let vs = VelocitySwitch(index: index) {
                velocitySwitch = vs
            }
            else {
                velocitySwitch = .all
                print("Value out of range for velocity switch: \(index). Using default value \(velocitySwitch)", to: &standardError)
            }
            
            isMuted = b.isBitSet(6)
            
            // M16: out select and mode
            b = buffer.next(&offset)

            index = Int(b & 0b00000111)
            if let sm = Submix(index: index) {
                submix = sm
            }
            else {
                submix = .a
                print("Value out of range for submix: \(index). Using default value \(submix)", to: &standardError)
            }

            index = Int((b & 0b00011000) >> 3)
            if let mode = PlayMode(index: index) {
                playMode = mode
            }
            else {
                playMode = .keyboard
                print("Value out of range for submix: \(index). Using default value \(playMode)", to: &standardError)
            }

            b = buffer.next(&offset)
            level = Int(b)
            
            b = buffer.next(&offset)
            transpose = Int(b) - 24
            
            b = buffer.next(&offset)
            tune = Int(b) - 50
        }
        
        /// Gets the SysEx data for the multi patch section.
        public var data: ByteArray {
            var d = ByteArray()
            
            // M12 / M20 etc.
            d.append(Byte(singlePatchNumber))
            
            // M13 / M21 etc.
            d.append(Byte(zone.low))
            
            // M14
            d.append(Byte(zone.high))
            
            // M15
            var m15 = channel - 1
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
            d.append(Byte(level))
            
            // M18
            d.append(Byte(transpose + 24))
            
            // M19
            d.append(Byte(tune + 50))
            
            return d
        }
    }

    static let dataSize = 77
    static let sectionCount = 8

    @PatchName public var name: String // 10 ASCII characters
    
    public var volume: Int  // 0~100 (from correction sheet, not 0~99)
    public var effect: Int  // 0~31/1~32
    
    public var sections = [Section]()
    
    /// Initializes a multi patch with default settings.
    public override init() {
        name = "Multi     "
        volume = 100
        effect = 1
        
        sections = Array(repeating: Section(), count: MultiPatch.sectionCount)
    }
    
    /// Initializes a multi patch from System Exclusive data bytes.
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0

        // Get the patch name from 10 bytes representing ASCII characters.
        // If that fails, use a string with 10 spaces. Also, replace any NULs with spaces.
        let originalName = String(bytes: buffer.slice(from: offset, length: PatchName.length), encoding: .ascii) ?? String(repeating: " ", count: PatchName.length)
        offset += PatchName.length
        self.name = originalName.replacingOccurrences(of: "\0", with: " ")
        //print("\(self.name):\n\(buffer.hexDump)")
        
        b = buffer.next(&offset)
        self.volume = Int(b)

        b = buffer.next(&offset)
        self.effect = Int(b + 1) // bring 0~31 to 1~32
        
        for _ in 0 ..< MultiPatch.sectionCount {
            let sectionData = buffer.slice(from: offset, length: Section.dataSize)
            sections.append(Section(bytes: sectionData))
            offset += Section.dataSize
        }
    }
    
    /// Gets the System Exclusive data for the multi patch.
    public var data: ByteArray {
        var d = ByteArray()
        
        // M0...M9 = name
        d.append(contentsOf: _name.asData())
        
        // M10
        d.append(Byte(volume))
        
        // M11
        d.append(Byte(effect - 1)) // 1~32 to 0~31
        
        // M12 / M20 / M28 / M36 / M44 / M52 / M60 / M68
        for section in sections {
            d.append(contentsOf: section.data)
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
}
