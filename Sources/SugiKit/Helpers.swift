import Foundation

extension String {
    /// Pads the string from left using `with` to `length`.
    public func pad(with character: String, toLength length: Int) -> String {
        let padCount = length - self.count
        guard padCount > 0 else {
            return self
        }

        return String(repeating: character, count: padCount) + self
    }
}

extension Byte {
    public mutating func setBit(_ position: Int) {
        self |= 1 << position;
    }
    
    public mutating func unsetBit(_ position: Int) {
        self &= ~(1 << position);
    }
    
    public func isBitSet(_ position: Int) -> Bool {
        return (self & (1 << position)) != 0
    }
    
    public func bitField(start: Int, end: Int) -> Byte {
        guard start >= 0 else {
            print("bit field start must not be negative")
            return 0
        }
        
        guard end >= 0 else {
            print("bit field end must not be negative")
            return 0
        }
        
        guard end < 8 else {
            print("not enough bits to cover bit field end \(end)")
            return 0
        }

        // Convert the byte into a bit string of exactly 8 characters (pad to zero from left as necessary)
        let allBits = self.bits
        let fieldBits = allBits[start ..< end]

        let byte = Byte.fromBits(bits: Array(fieldBits))
        return byte
    }
    
    // Returns the value of the bits from start to end-1 (zero-based bit positions counted from the right)
    public func bitFieldWithShift(start: Int, end: Int) -> Byte {
        guard start >= 0 else {
            print("bit field start must not be negative")
            return 0
        }
        
        guard end >= 0 else {
            print("bit field end must not be negative")
            return 0
        }
        
        guard end < 8 else {
            print("not enough bits to cover bit field end \(end)")
            return 0
        }

        print("getting bit field from \(start) to \(end)")
        
        // shift the bits we want to the bottom of the byte
        let allBits = self >> start
        print("shifted right by \(start) to get \(allBits)")
        
        let length = end - start
        print("length is \(length)")
        let fieldBits = allBits & (1 << length)
        print("allBits & (1 << length) = \(allBits) & (1 << \(length)) = \(allBits) & \(1 << length) = \(fieldBits)")
        return fieldBits
    }
}

extension Byte {
    public func toBinary() -> String {
        return String(self, radix: 2)
    }
    
    public func toHex(digits: Int = 2) -> String {
        return String(format: "%0\(digits)x", self)
    }
}

// The Bit enum and the bits -> [Bit] function: https://stackoverflow.com/a/44808203/1016326
public enum Bit: Byte, CustomStringConvertible {
    case zero, one

    public var description: String {
        switch self {
        case .one:
            return "1"
        case .zero:
            return "0"
        }
    }
}

public typealias BitArray = [Bit]

extension Byte {
    // Returns an array of exactly eight Bit objects, with bit #0 first
    public var bits: BitArray {
        var byte = self
        var bits = BitArray(repeating: .zero, count: 8)
        for i in 0..<8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }

            byte >>= 1
        }
        return bits
    }
    
    // Returns a byte constructed from an array of Bit objects, with bit #0 first.
    // If the array has less than eight bits, pad it with zero bits from the left.
    public static func fromBits(bits: BitArray) -> Byte {
        var myBits = bits
        
        //print("initially myBits has \(myBits.count) Bit elements")
        while myBits.count < 8 {
            myBits.append(.zero)
        }
        //print("after checking it has \(myBits.count) Bit elements")
        
        var byte: Byte = 0
        for (position, bit) in myBits.enumerated() {
            if bit == .one {
                byte |= 1 << position
            }
        }
        
        return byte
    }
}

extension Data {
    public var bytes: ByteArray {
        var byteArray = ByteArray(repeating: 0, count: self.count)
        self.copyBytes(to: &byteArray, count: self.count)
        return byteArray
    }
    
    public var hexDump: String {
        var s = ""
        for d in self {
            s += d.toHex(digits: 2)
            s += " "
        }
        return s
    }
}

extension ByteArray {
    public var hexDump: String {
        var s = ""
        var count = 1
        for b in self {
            s += b.toHex(digits: 2) + " "
            count += 1
            if count == 8 {
                s += "\n"
                count = 1
            }
        }
        return s

    }
    
    /// Returns the byte at the given offset, then increases the offset by one.
    public func next(_ offset: inout Int) -> Byte {
        let b = self[offset]
        offset += 1
        return b
    }
    
    /// Returns a new byte array with `length` bytes starting from `offset`.
    public func slice(from offset: Int, length: Int) -> ByteArray {
        return ByteArray(self[offset ..< offset + length])
    }
}

extension Double {
    /// Rounds the double to decimal places value
    public func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// https://ericasadun.com/2018/12/14/more-fun-with-swift-5-string-interpolation-radix-formatting/
public extension String.StringInterpolation {
    /// Represents a single numeric radix
    enum Radix: Int {
        case binary = 2, octal = 8, decimal = 10, hex = 16
        
        /// Returns a radix's optional prefix
        var prefix: String {
             return [.binary: "0b", .octal: "0o", .hex: "0x"][self, default: ""]
        }
    }
    
    /// Return padded version of the value using a specified radix
    mutating func appendInterpolation<I: BinaryInteger>(_ value: I, radix: Radix, prefix: Bool = false, toWidth width: Int = 0) {
        
        // Values are uppercased, producing `FF` instead of `ff`
        var string = String(value, radix: radix.rawValue).uppercased()
        
        // Strings are pre-padded with 0 to match target widths
        if string.count < width {
            string = String(repeating: "0", count: max(0, width - string.count)) + string
        }
        
        // Prefixes use lower case, sourced from `String.StringInterpolation.Radix`
        if prefix {
            string = radix.prefix + string
        }
        
        appendInterpolation(string)
    }
}

extension String {
    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

public func noteName(for key: Int) -> String {
    let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    let octave = key / 12 - 1
    let name = noteNames[key % 12];
    return "\(name)\(octave)"
}

public func keyNumber(for name: String) -> Int {
    let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    var i = 0
    var notePart = ""
    var octavePart = ""
    while i < name.count {
        let c = name[i ..< i + 1]
        if c == "C" || c == "D" || c == "E" || c == "F" || c == "G" || c == "A" || c == "B" {
            notePart += c
        }
        if c == "#" {
            notePart += c
        }
        if c == "-" {
            octavePart += c
        }
        if c == "0" || c == "1" || c == "2" || c == "3" || c == "4" || c == "5" || c == "6" || c == "7" || c == "8" || c == "9" {
            octavePart += c
        }
        i += 1
    }

    if let octave = Int(octavePart), let noteIndex = names.firstIndex(where: { $0 == notePart }) {
        return (octave + 1) * 12 + noteIndex
    }

    return 0
}

public func patchName(patchNumber: Int, patchCount: Int = 16) -> String {
    let bankIndex = patchNumber / patchCount
    let bankLetter = ["A", "B", "C", "D"][bankIndex]
    let patchIndex = (patchNumber % patchCount) + 1
    return "\(bankLetter)-\(patchIndex)"
}

public func everyNthByte(d: ByteArray, n: Int, start: Int) -> ByteArray {
    var result = ByteArray()
    
    for i in 0 ..< d.count {
        if i % n == 0 {
            result.append(d[i + start])
        }
    }
    
    return result
}
