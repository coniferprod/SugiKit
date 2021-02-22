import Foundation

public typealias Byte = UInt8
public typealias ByteArray = [Byte]

let headerLength = 8

let singlePatchCount = 64
let singlePatchDataLength = 131

let multiPatchCount = 64
let multiPatchDataLength = 77

let drumHeaderLength = 11
let drumDataLength = 682
let drumNoteCount = 61
let drumNoteLength = 11

let effectPatchCount = 32
let effectPatchDataLength = 35

let allPatchDataLength = 15_123  // full bank, including SysEx header

let totalDataLength =
    headerLength +
    singlePatchCount * singlePatchDataLength +
    multiPatchCount * multiPatchDataLength +
    effectPatchCount * effectPatchDataLength +
    1

public enum PatchType: String, CaseIterable {
    case single
    case multi
    case effect
    case drum
}

public enum VelocityCurveType: Int, Codable, CaseIterable {
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

public enum KeyScalingCurveType: Int, Codable, CaseIterable {
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

public struct KeyType: Codable {
    var key: Int // 0~115 / C-1~G8
    var name: String {
        get {
            let number = key
            let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
            let octave = number / 12 - 1
            let name = noteNames[number % 12];
            return "\(name)\(octave)"
        }
    }
    
    public init() {
        key = 0
    }
    
    public init(key: Int) {
        self.key = key
    }
}

public struct ZoneType: Codable {
    public var low: Int
    public var high: Int
    public var velocitySwitch: VelocitySwitchType
    
    public init() {
        low = 0
        high = 0
        velocitySwitch = .all
    }
}

public enum PlayModeType: String, Codable, CaseIterable {
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

public enum VelocitySwitchType: String, Codable, CaseIterable {
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

public enum SubmixType: String, Codable, CaseIterable {
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

public enum SourceModeType: String, Codable, CaseIterable {
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

public enum PolyphonyModeType: String, Codable, CaseIterable {
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

public enum WheelAssignType: String, Codable, CaseIterable {
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

public struct AutoBendSettings: Codable, CustomStringConvertible {
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
    
    public var description: String {
        return "Auto bend settings: time = \(time), depth = \(depth), KS time = \(keyScalingTime), vel depth = \(velocityDepth)"
    }
}

public struct LevelModulation: Codable, Equatable {
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
}

public struct TimeModulation: Codable, Equatable {
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
}
