import Foundation

import SyxPack


extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index {
        return Self.allCases.firstIndex(of: self)!
    }
}

public enum PatchKind: String, CaseIterable {
    case unknown
    case single
    case multi
    case effect
    case drum
}

public enum VelocityCurve: Int, Codable, CaseIterable {
    case curve1 = 1
    case curve2
    case curve3
    case curve4
    case curve5
    case curve6
    case curve7
    case curve8
    
    init?(index: Int) {
        switch index {
        case 1: self = .curve1
        case 2: self = .curve2
        case 3: self = .curve3
        case 4: self = .curve4
        case 5: self = .curve5
        case 6: self = .curve6
        case 7: self = .curve7
        case 8: self = .curve8
        default: return nil
        }
    }
}

public enum KeyScalingCurve: Int, Codable, CaseIterable {
    case curve1 = 1
    case curve2
    case curve3
    case curve4
    case curve5
    case curve6
    case curve7
    case curve8
    
    init?(index: Int) {
        switch index {
        case 1: self = .curve1
        case 2: self = .curve2
        case 3: self = .curve3
        case 4: self = .curve4
        case 5: self = .curve5
        case 6: self = .curve6
        case 7: self = .curve7
        case 8: self = .curve8
        default: return nil
        }
    }
}

public struct Zone: Codable, Equatable {
    public var low: Int
    public var high: Int
    public var velocitySwitch: VelocitySwitch
    
    public init() {
        low = 0
        high = 0
        velocitySwitch = .all
    }
}

public enum PlayMode: String, Codable, CaseIterable {
    case keyboard
    case midi
    case mix

    init?(index: Int) {
        switch index {
        case 0: self = .keyboard
        case 1: self = .midi
        case 2: self = .mix
        default: return nil
        }
    }
}

public enum VelocitySwitch: String, Codable, CaseIterable, Equatable {
    case soft
    case loud
    case all
    
    init?(index: Int) {
        switch index {
        case 0: self = .soft
        case 1: self = .loud
        case 2: self = .all
        default: return nil
        }
    }
}

public enum Submix: String, Codable, CaseIterable, Equatable {
    case a = "a"
    case b = "b"
    case c = "c"
    case d = "d"
    case e = "e"
    case f = "f"
    case g = "g"
    case h = "h"
    
    init?(index: Int) {
        switch index {
        case 0: self = .a
        case 1: self = .b
        case 2: self = .c
        case 3: self = .d
        case 4: self = .e
        case 5: self = .f
        case 6: self = .g
        case 7: self = .h
        default: return nil
        }
    }
}

public enum SourceMode: String, Codable, CaseIterable {
    case normal
    case twin
    case double
    
    init?(index: Int) {
        switch index {
        case 0: self = .normal
        case 1: self = .twin
        case 2: self = .double
        default: return nil
        }
    }
}

public enum PolyphonyMode: String, Codable, CaseIterable {
    case poly1
    case poly2
    case solo1
    case solo2

    init?(index: Int) {
        switch index {
        case 0: self = .poly1
        case 1: self = .poly2
        case 2: self = .solo1
        case 3: self = .solo2
        default: return nil
        }
    }
}

public enum WheelAssign: String, Codable, CaseIterable {
    case vibrato
    case lfo
    case cutoff

    init?(index: Int) {
        switch index {
        case 0: self = .vibrato
        case 1: self = .lfo
        case 2: self = .cutoff
        default: return nil
        }
    }
}

public struct AutoBend: Codable, Equatable, CustomStringConvertible {
    static let dataSize = 4
    
    public var time: UInt  // 0~100
    public var depth: Int  // -50~+50
    public var keyScalingTime: Int  // -50~+50
    public var velocityDepth: Int  // -50~+50
    
    public init() {
        time = 0
        depth = 0
        keyScalingTime = 0
        velocityDepth = 0
    }
    
    public init(time: UInt, depth: Int, keyScalingTime: Int, velocityDepth: Int) {
        self.time = time
        self.depth = depth
        self.keyScalingTime = keyScalingTime
        self.velocityDepth = velocityDepth
    }
    
    public static func parse(from data: ByteArray) -> Result<AutoBend, ParseError> {
        var offset = 0
        var b: Byte = 0x00
        
        var temp = AutoBend()
        
        b = data.next(&offset)
        temp.time = UInt(b & 0x7f)

        b = data.next(&offset)
        temp.depth = Int((b & 0x7f)) - 50 // 0~100 to ±50

        b = data.next(&offset)
        temp.keyScalingTime = Int((b & 0x7f)) - 50 // 0~100 to ±50

        b = data.next(&offset)
        temp.velocityDepth = Int((b & 0x7f)) - 50 // 0~100 to ±50

        return .success(temp)
    }
    
    public var description: String {
        return "Auto bend settings: time = \(time), depth = \(depth), KS time = \(keyScalingTime), vel depth = \(velocityDepth)"
    }
}

public struct LevelModulation: Codable, Equatable, CustomStringConvertible {
    // this private property determines the allowed values
    private let range = -50...50
    
    // but we don't want the range to end up in the JSON representation
    private enum CodingKeys: String, CodingKey {
        case velocityDepth, pressureDepth, keyScalingDepth
    }
    
    // use didSet to clamp the value to the range
    public var velocityDepth: Int = 0 {  // -50...50
        didSet {
            if velocityDepth > range.upperBound {
                velocityDepth = range.upperBound
            }
            if velocityDepth < range.lowerBound {
                velocityDepth = range.lowerBound
            }
        }
    }
    
    public var pressureDepth: Int = 0 // -50...50
    public var keyScalingDepth: Int = 0 // -50...50
    
    public init() {
        velocityDepth = 0
        pressureDepth = 0
        keyScalingDepth = 0
    }
    
    public init(velocityDepth: Int, pressureDepth: Int, keyScalingDepth: Int) {
        self.velocityDepth = velocityDepth
        self.pressureDepth = pressureDepth
        self.keyScalingDepth = keyScalingDepth
    }
    
    public static func parse(from data: ByteArray) -> Result<LevelModulation, ParseError> {
        var offset = 0
        var b: Byte = 0x00
        
        var temp = LevelModulation()
        
        b = data.next(&offset)
        temp.velocityDepth = Int(b) - 50

        b = data.next(&offset)
        temp.pressureDepth = Int(b) - 50
        
        b = data.next(&offset)
        temp.keyScalingDepth = Int(b) - 50
        
        return .success(temp)
    }
    
    private var data: ByteArray {
        var buf = ByteArray()
        buf.append(contentsOf: [
            Byte(self.velocityDepth + 50),
            Byte(self.pressureDepth + 50),
            Byte(self.keyScalingDepth + 50)
        ])
        return buf
    }
    
    public static let dataSize = 3
    
    public var description: String {
        return "Vel.depth=\(velocityDepth) Prs.depth=\(pressureDepth) KSDepth=\(keyScalingDepth)"
    }
}

public struct TimeModulation: Codable, Equatable, CustomStringConvertible {
    public var attackVelocity: Int  // -50~+50
    public var releaseVelocity: Int  // -50~+50
    public var keyScaling: Int  // -50~+50
    
    public init() {
        attackVelocity = 0
        releaseVelocity = 0
        keyScaling = 0
    }
    
    public init(attackVelocity: Int, releaseVelocity: Int, keyScaling: Int) {
        self.attackVelocity = attackVelocity
        self.releaseVelocity = releaseVelocity
        self.keyScaling = keyScaling
    }
    
    public static func parse(from data: ByteArray) -> Result<TimeModulation, ParseError> {
        var offset = 0
        var b: Byte = 0x00
        
        var temp = TimeModulation()
        
        b = data.next(&offset)
        temp.attackVelocity = Int(b) - 50
        
        b = data.next(&offset)
        temp.releaseVelocity = Int(b) - 50

        b = data.next(&offset)
        temp.keyScaling = Int(b) - 50
                
        return .success(temp)
    }

    private var data: ByteArray {
        var buf = ByteArray()
        buf.append(contentsOf: [
            Byte(self.attackVelocity + 50),
            Byte(self.releaseVelocity + 50),
            Byte(self.keyScaling + 50)
        ])
        return buf
    }
    
    public static let dataSize = 3
    
    public var description: String {
        return "AtkVel=\(attackVelocity) RelVel=\(releaseVelocity) KS=\(keyScaling)"
    }
}

/// Key with note number and name.
public struct Key: Codable, Equatable, CustomStringConvertible {
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    public var note: Int
    
    /// Name of the key.
    public var name: String {
        let octave = self.note / 12 - 1
        let name = Key.noteNames[self.note % 12]
        return "\(name)\(octave)"
    }

    /// Initialize the key with a note number.
    public init(note: Int) {
        self.note = note
    }
    
    /// Get the key corresponding to a note name.
    public static func key(for name: String) -> Key? {
        let notes = CharacterSet(charactersIn: "CDEFGAB")
        
        var i = 0
        var notePart = ""
        var octavePart = ""
        while i < name.count {
            let c = name[i ..< i + 1]
            
            let isNote = c.unicodeScalars.allSatisfy { notes.contains($0) }
            if isNote {
                notePart += c
            }
            else {
                return nil
            }
     
            if c == "#" {
                notePart += c
            }
            if c == "-" {
                octavePart += c
            }
            
            let isDigit = c.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
            if isDigit {
                octavePart += c
            }

            i += 1
        }

        if let octave = Int(octavePart), let noteIndex = Key.noteNames.firstIndex(where: { $0 == notePart }) {
            return Key(note: (octave + 1) * 12 + noteIndex)
        }

        return nil
    }
    
    public var description: String {
        return self.name
    }
}

// MARK: - SystemExclusiveData conformance

extension AutoBend: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        [Byte(time), Byte(depth + 50), Byte(keyScalingTime + 50), Byte(velocityDepth + 50)].forEach {
            buf.append($0)
        }
        return buf
    }
    
    public var dataLength: Int { AutoBend.dataSize }
}

extension LevelModulation: SystemExclusiveData {
    /// Gets the level modulation data as MIDI System Exclusive data bytes.
    public func asData() -> ByteArray {
        return self.data
    }

    /// Gets the length of the level modulation data.
    public var dataLength: Int { LevelModulation.dataSize }
}

extension TimeModulation: SystemExclusiveData {
    /// Gets the time modulation data as MIDI System Exclusive data bytes.
    public func asData() -> ByteArray {
        return self.data
    }

    /// Gets the length of the time modulation data.
    public var dataLength: Int { TimeModulation.dataSize }
}
