import Foundation

public struct LFO: Codable, Equatable {
    public enum Shape: String, Codable, CaseIterable {
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

    public var shape: Shape
    public var speed: Int
    public var delay: Int  // 0~100
    public var depth: Int  // -50~+50
    public var pressureDepth: Int  // -50~+50
    
    static let dataSize = 5
    
    public init() {
        shape = .triangle
        speed = 0
        delay = 0
        depth = 0
        pressureDepth = 0
    }
    
    public init(shape: Shape, speed: Int, delay: Int, depth: Int, pressureDepth: Int) {
        self.shape = shape
        self.speed = speed
        self.delay = delay
        self.depth = depth
        self.pressureDepth = pressureDepth
    }
    
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0x00
        var index = 0
        
        b = buffer.next(&offset)
        index = Int(b & 0x03)
        shape = Shape(index: index)!

        b = buffer.next(&offset)
        speed = Int(b & 0x7f)

        b = buffer.next(&offset)
        delay = Int(b & 0x7f)

        b = buffer.next(&offset)
        depth = Int((b & 0x7f)) - 50 // 0~100 to ±50

        b = buffer.next(&offset)
        pressureDepth = Int((b & 0x7f)) - 50 // 0~100 to ±50
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        [shape.index, speed, delay, depth + 50, pressureDepth + 50].forEach {
            buf.append(Byte($0))
        }
        return buf
    }
    
    // Another way of implementing the `data` property would be something like this:
    // `return [Byte(shape.index!), Byte(speed), Byte(delay), Byte(depth + 50), Byte(pressureDepth + 50)]`
    // but that is riddled with typecasts to `Byte`.
}

public struct Vibrato: Codable, Equatable {
    public var shape: LFO.Shape
    public var speed: Int  // 0~100
    public var depth: Int  // -50+~50
    public var pressureDepth: Int  // -50+~+50
    
    public init() {
        shape = .triangle
        speed = 0
        depth = 0
        pressureDepth = 0
    }
    
    public init(shape: LFO.Shape, speed: Int, depth: Int, pressureDepth: Int) {
        self.shape = shape
        self.speed = speed
        self.depth = depth
        self.pressureDepth = pressureDepth
    }
    
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0x00
        var index = 0
        
        b = buffer.next(&offset)
        index = Int(b.bitField(start: 4, end: 6))
        if let vibratoShape = LFO.Shape(index: index) {
            shape = vibratoShape
        }
        else {
            shape = .triangle
            print("Value out of range for vibrato shape: \(index). Using default value \(shape).", to: &standardError)
        }

        b = buffer.next(&offset)
        // Vibrato speed = s16 bits 0...6
        speed = Int(b & 0x7f)
        
        b = buffer.next(&offset)
        pressureDepth = Int((b & 0x7f)) - 50 // 0~100 to ±50
        
        b = buffer.next(&offset)
        depth = Int((b & 0x7f)) - 50 // 0~100 to ±50
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        [shape.index, speed, depth + 50, pressureDepth + 50].forEach {
            buf.append(Byte($0))
        }
        return buf
    }
}

// Note that the LFO and Vibrato structs are nearly identical.
// Structs don't have inheritance, but using a protocol here
// seems weird somehow. So let's bear a bit of code duplication.
