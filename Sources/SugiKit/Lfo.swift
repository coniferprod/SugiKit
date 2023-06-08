import Foundation

import SyxPack

/// LFO settings.
public struct LFO: Codable, Equatable {
    /// LFO shapes.
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
    public var speed: UInt  // 0~100
    public var delay: UInt  // 0~100
    public var depth: Int  // -50~+50
    public var pressureDepth: Int  // -50~+50
    
    static let dataSize = 5
    
    /// Initializes an LFO with default values.
    public init() {
        shape = .triangle
        speed = 0
        delay = 0
        depth = 0
        pressureDepth = 0
    }
    
    /// Initializes an LFO with the specified values.
    public init(shape: Shape, speed: UInt, delay: UInt, depth: Int, pressureDepth: Int) {
        self.shape = shape
        self.speed = speed
        self.delay = delay
        self.depth = depth
        self.pressureDepth = pressureDepth
    }

    /// Parses an LFO from MIDI System Exclusive data bytes.
    public static func parse(from data: ByteArray) -> Result<LFO, ParseError> {
        var offset = 0
        var b: Byte = 0x00
        var index = 0
        
        var temp = LFO()
        
        b = data.next(&offset)
        index = Int(b & 0x03)
        if let lfoShape = Shape(index: index) {
            temp.shape = lfoShape
        }
        else {
            return .failure(.invalidData(offset))
        }

        b = data.next(&offset)
        temp.speed = UInt(b & 0x7f)

        b = data.next(&offset)
        temp.delay = UInt(b & 0x7f)

        b = data.next(&offset)
        temp.depth = Int((b & 0x7f)) - 50 // 0~100 to ±50

        b = data.next(&offset)
        temp.pressureDepth = Int((b & 0x7f)) - 50 // 0~100 to ±50

        return .success(temp)
    }
}

public struct Vibrato: Codable, Equatable {
    public var shape: LFO.Shape
    public var speed: UInt  // 0~100
    public var depth: Int  // -50+~50
    public var pressureDepth: Int  // -50+~+50
    
    public init() {
        shape = .triangle
        speed = 0
        depth = 0
        pressureDepth = 0
    }
    
    public init(shape: LFO.Shape, speed: UInt, depth: Int, pressureDepth: Int) {
        self.shape = shape
        self.speed = speed
        self.depth = depth
        self.pressureDepth = pressureDepth
    }
    
    public static func parse(from data: ByteArray) -> Result<Vibrato, ParseError> {
        var offset = 0
        var b: Byte = 0x00
        var index = 0
        
        var temp = Vibrato()
        
        b = data.next(&offset)
        index = Int(b.bitField(start: 4, end: 6))
        if let vibratoShape = LFO.Shape(index: index) {
            temp.shape = vibratoShape
        }
        else {
            return .failure(.invalidData(offset))
        }

        b = data.next(&offset)
        // Vibrato speed = s16 bits 0...6
        temp.speed = UInt(b & 0x7f)
        
        b = data.next(&offset)
        temp.pressureDepth = Int((b & 0x7f)) - 50 // 0~100 to ±50
        
        b = data.next(&offset)
        temp.depth = Int((b & 0x7f)) - 50 // 0~100 to ±50

        return .success(temp)
    }
    
    private var data: ByteArray {
        var buf = ByteArray()
        
        buf.append(Byte(shape.index))
        buf.append(Byte(speed))
        buf.append(Byte(depth + 50))
        buf.append(Byte(pressureDepth + 50))

        return buf
    }
    
    public static let dataSize = 4
}

// Note that the LFO and Vibrato structs are nearly identical.
// Structs don't have inheritance, but using a protocol here
// seems weird somehow. So let's bear a bit of code duplication.

// MARK: - SystemExclusiveData conformance

extension LFO: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        
        buf.append(Byte(shape.index))
        buf.append(Byte(speed))
        buf.append(Byte(delay))
        buf.append(Byte(depth + 50))
        buf.append(Byte(pressureDepth + 50))

        return buf
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { LFO.dataSize }
}

extension Vibrato: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        
        buf.append(Byte(shape.index))
        buf.append(Byte(speed))
        buf.append(Byte(depth + 50))
        buf.append(Byte(pressureDepth + 50))
        
        return buf
    }
    
    public var dataLength: Int { Vibrato.dataSize }
}
