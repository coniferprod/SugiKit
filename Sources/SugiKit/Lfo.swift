import Foundation

public enum LFOShapeType: String, Codable, CaseIterable {
    case triangle
    case sawtooth
    case square
    case random
    
    init?(index: Int) {
        switch index {
        case 0: self = .triangle
        case 1: self = .sawtooth
        case 2: self = .square
        case 3: self = .random
        default: return nil
        }
    }
}

public struct VibratoSettings: Codable {
    public var shape: LFOShapeType
    public var speed: Int  // 0~100
    public var depth: Int  // -50+~50
    public var pressureDepth: Int  // -50+~+50
    
    public init() {
        shape = .triangle
        speed = 0
        depth = 0
        pressureDepth = 0
    }
}

public struct LFOSettings: Codable {
    public var shape: LFOShapeType
    public var speed: Int
    public var delay: Int
    public var depth: Int  // -50~+50
    public var pressureDepth: Int  // -50~+50
    
    public init() {
        shape = .triangle
        speed = 0
        delay = 0
        depth = 0
        pressureDepth = 0
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        [shape.index!, speed, delay, depth + 50, pressureDepth + 50].forEach {
            buf.append(Byte($0))
        }
        
        return buf
    }
}
