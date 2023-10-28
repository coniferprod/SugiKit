import Foundation

import SyxPack

/// LFO settings.
public struct LFO: Equatable {
    /// Compares two LFO instances.
    public static func == (lhs: LFO, rhs: LFO) -> Bool {
        return lhs.shape == rhs.shape
        && lhs.speed == rhs.speed
        && lhs.delay == rhs.delay
        && lhs.depth == rhs.depth
        && lhs.pressureDepth == rhs.pressureDepth
    }
    
    /// LFO shapes.
    public enum Shape: String, Codable, CaseIterable {
        case triangle
        case sawtooth
        case square
        case random
        
        public init?(index: Int) {
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
    public var speed: Level  // 0~100
    public var delay: Level  // 0~100
    public var depth: Depth  // -50~+50
    public var pressureDepth: Depth  // -50~+50

    /// The data size of this LFO.
    public static let dataSize = 5
    
    /// Initializes an LFO with default values.
    public init() {
        shape = .triangle
        speed = Level(0)
        delay = Level(0)
        depth = Depth(0)
        pressureDepth = Depth(0)
    }
    
    /// Initializes an LFO with the specified values.
    public init(shape: Shape, speed: Int, delay: Int, depth: Int, pressureDepth: Int) {
        self.shape = shape
        self.speed = Level(speed)
        self.delay = Level(delay)
        self.depth = Depth(depth)
        self.pressureDepth = Depth(pressureDepth)
    }

    /// Parses an LFO from MIDI System Exclusive data bytes.
    /// - Parameter data: the System Exclusive data
    /// - Returns: A result type with valid `LFO` data, or an instance of `ParseError`.
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
        temp.speed = Level(Int(b & 0x7f))

        b = data.next(&offset)
        temp.delay = Level(Int(b & 0x7f))

        b = data.next(&offset)
        temp.depth = Depth(Int((b & 0x7f)) - 50) // 0~100 to ±50

        b = data.next(&offset)
        temp.pressureDepth = Depth(Int((b & 0x7f)) - 50) // 0~100 to ±50

        return .success(temp)
    }
}

public struct Vibrato: Equatable {
    /// Compares two vibrato instances.
    public static func == (lhs: Vibrato, rhs: Vibrato) -> Bool {
        return lhs.shape == rhs.shape
        && lhs.speed == rhs.speed
        && lhs.depth == rhs.depth
        && lhs.pressureDepth == rhs.pressureDepth
    }
    
    public var shape: LFO.Shape
    public var speed: Level  // 0~100
    public var depth: Depth  // -50+~50
    public var pressureDepth: Depth  // -50+~+50
    
    /// Initializes vibrato with default settings.
    public init() {
        shape = .triangle
        speed = Level(0)
        depth = Depth(0)
        pressureDepth = Depth(0)
    }
    
    /// Initializes vibrato with the specified settings as primitive values.
    public init(shape: LFO.Shape, speed: Int, depth: Int, pressureDepth: Int) {
        self.shape = shape
        self.speed = Level(speed)
        self.depth = Depth(depth)
        self.pressureDepth = Depth(pressureDepth)
    }
    
    /// Initializes vibrato with the specified Level and Depth values.
    public init(shape: LFO.Shape, speed: Level, depth: Depth, pressureDepth: Depth) {
        self.shape = shape
        self.speed = speed
        self.depth = depth
        self.pressureDepth = pressureDepth
    }
    
    /// Parses vibrato from MIDI System Exclusive data bytes.
    /// - Parameter data: the System Exclusive data
    /// - Returns: A result type with valid `Vibrato` data, or an instance of `ParseError`.
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
        temp.speed = Level(Int(b & 0x7f))
        
        b = data.next(&offset)
        temp.pressureDepth = Depth(Int(b & 0x7f) - 50) // 0~100 to ±50
        
        b = data.next(&offset)
        temp.depth = Depth(Int(b & 0x7f) - 50) // 0~100 to ±50

        return .success(temp)
    }
    
    private var data: ByteArray {
        var buf = ByteArray()
        
        buf.append(Byte(shape.index))
        buf.append(Byte(speed.value))
        buf.append(Byte(depth.value + 50))
        buf.append(Byte(pressureDepth.value + 50))

        return buf
    }
    
    /// The data size of this vibrato instance.
    public static let dataSize = 4
}

// Note that the LFO and Vibrato structs are nearly identical.
// Structs don't have inheritance, but using a protocol here
// seems weird somehow. So let's bear a bit of code duplication.

// MARK: - SystemExclusiveData conformance

extension LFO: SystemExclusiveData {
    /// Gets the System Exclusive data for the LFO.
    public func asData() -> ByteArray {
        var buf = ByteArray()
        
        buf.append(Byte(shape.index))
        buf.append(Byte(speed.value))
        buf.append(Byte(delay.value))
        buf.append(Byte(depth.value + 50))
        buf.append(Byte(pressureDepth.value + 50))

        return buf
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { LFO.dataSize }
}

extension Vibrato: SystemExclusiveData {
    /// Gets the System Exclusive data for the vibrato.
    public func asData() -> ByteArray {
        var buf = ByteArray()
        
        buf.append(Byte(shape.index))
        buf.append(Byte(speed.value))
        buf.append(Byte(depth.value + 50))
        buf.append(Byte(pressureDepth.value + 50))
        
        return buf
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { Vibrato.dataSize }
}
