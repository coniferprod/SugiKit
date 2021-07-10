import Foundation

public typealias Byte = UInt8
public typealias ByteArray = [Byte]

extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}

public enum PatchKind: String, CaseIterable {
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

public struct Zone: Codable {
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

public enum VelocitySwitch: String, Codable, CaseIterable {
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

public enum Submix: String, Codable, CaseIterable {
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

public struct AutoBend: Codable, CustomStringConvertible {
    public var time: Int
    public var depth: Int
    public var keyScalingTime: Int
    public var velocityDepth: Int
    
    public init() {
        time = 0
        depth = 0
        keyScalingTime = 0
        velocityDepth = 0
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        [time, depth + 50, keyScalingTime + 50, velocityDepth + 50].forEach {
            buf.append(Byte($0))
        }
        
        return buf
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
    
    public var data: ByteArray {
        var buf = ByteArray()
        buf.append(contentsOf: [
            Byte(self.velocityDepth + 50),
            Byte(self.pressureDepth + 50),
            Byte(self.keyScalingDepth + 50)
        ])
            
        return buf
    }
    
    public var description: String {
        return "Vel.depth=\(velocityDepth) Prs.depth=\(pressureDepth) KSDepth=\(keyScalingDepth)"
    }
}

public struct TimeModulation: Codable, Equatable, CustomStringConvertible {
    public var attackVelocity: Int
    public var releaseVelocity: Int
    public var keyScaling: Int
    
    public init() {
        attackVelocity = 0
        releaseVelocity = 0
        keyScaling = 0
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        buf.append(contentsOf: [
            Byte(self.attackVelocity + 50),
            Byte(self.releaseVelocity + 50),
            Byte(self.keyScaling + 50)
        ])
        
        return buf
    }
    
    public var description: String {
        return "AtkVel=\(attackVelocity) RelVel=\(releaseVelocity) KS=\(keyScaling)"
    }
}

public struct FixedKey: Codable, Equatable, CustomStringConvertible {
    public var key: Byte
    
    public static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    public static func noteName(for key: Int) -> String {
        let octave = key / 12 - 1
        let name = FixedKey.noteNames[key % 12];
        return "\(name)\(octave)"
    }

    public static func keyNumber(for name: String) -> Int {
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

        if let octave = Int(octavePart), let noteIndex = FixedKey.noteNames.firstIndex(where: { $0 == notePart }) {
            return (octave + 1) * 12 + noteIndex
        }

        return 0
    }

    public var description: String {
        return FixedKey.noteName(for: Int(self.key))
    }
}
