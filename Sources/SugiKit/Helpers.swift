import Foundation

import ByteKit
import SyxPack


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
    /// Returns the value of the bits from start to end-1 (zero-based bit positions counted from the right)
    public func bitFieldWithShift(start: Int, end: Int) -> Byte {
        guard 
            start >= 0 
        else {
            print("bit field start must not be negative", to: &standardError)
            return 0
        }
        
        guard 
            end >= 0
        else {
            print("bit field end must not be negative", to: &standardError)
            return 0
        }
        
        guard 
            end < 8
        else {
            print("not enough bits to cover bit field end \(end)", to: &standardError)
            return 0
        }

        // shift the bits we want to the bottom of the byte
        let allBits = self >> start
        
        let length = end - start
        let fieldBits = allBits & (1 << length)
        return fieldBits
    }
}

extension ByteArray {
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

    /// Returns a new `ByteArray` with every nth bytes of this array.
    public func everyNthByte(n: Int, start: Int = 0) -> ByteArray {
        var result = ByteArray()
        
        for i in 0 ..< self.count {
            if i % n == 0 {
                result.append(self[i + start])
            }
        }
        
        return result
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
    // Represents a single numeric radix
    enum Radix: Int {
        case binary = 2, octal = 8, decimal = 10, hex = 16
        
        /// Returns a radix's optional prefix
        var prefix: String {
             return [.binary: "0b", .octal: "0o", .hex: "0x"][self, default: ""]
        }
    }
    
    // Returns a padded version of the value using the specified radix
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
    /// Alias for the character count.
    public var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    public func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    public func substring(toIndex: Int) -> String {
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

public enum PadFrom {
    case left
    case right
}

extension String {
    public func pad(with character: String, toLength length: Int, from: PadFrom = .right) -> String {
        let padCount = length - self.count
        guard padCount > 0 else {
            return self
        }

        if from == .left {
            return String(repeating: character, count: padCount) + self
        }
        else {
            return self + String(repeating: character, count: padCount)
        }
    }
}

extension String {
    /// Returns this string adjusted to the given length, and padded as necessary
    /// with the given character from the right.
    public func adjusted(length: Int, pad: String = " ") -> String {
        // If longer, truncate to `length`.
        // If shorter, pad from right with `pad` to the length `length`.
        if self.count > length {
            return String(self.prefix(length))
        }
        else {
            return self.pad(with: " ", toLength: length, from: .right)
            //return self.padding(toLength: length, withPad: " ", startingAt: self.count - 1)
        }
    }
}

func checksum(bytes: ByteArray) -> Byte {
    var totalSum = bytes.reduce(0) { $0 + (Int($1) & 0xff) }
    totalSum += 0xa5
    return Byte(totalSum & 0x7f)
}

/// Represents the name of a single or multi patch.
public struct PatchName: Equatable, Codable {
    /// Length of patch name in characters.
    public static let length = 10
    
    private(set) var _value: String = PatchName.wrapped(name: " ")
    
    private static func wrapped(name: String) -> String {
        return name.adjusted(length: PatchName.length, pad: " ")
    }
    
    /// Value of the wrapped String.
    public var value: String {
        get {
            return _value
        }
        
        set {
            self._value = PatchName.wrapped(name: newValue)
        }
    }
        
    /// Initializes the patch name from a `String`.
    /// The name is padded or truncated to `length` characters if necessary.
    public init(_ name: String) {
        self.value = name  // let property setter handle the adjustment
    }
    
    /// Initializes the patch name from MIDI System Exclusive data bytes.
    public init(data: ByteArray) {
        self.value = String(data: Data(data), encoding: .ascii) ?? "--------"
    }
    
    /// Parse a patch name from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<PatchName, ParseError> {
        var temp = PatchName("")
        if let name = String(bytes: data, encoding: .ascii) {
            temp.value = name.replacingOccurrences(of: "\0", with: " ")
            return .success(temp)
        }
        else {
            return .failure(.invalidData(0))
        }
    }
}

// MARK: - SystemExclusiveData

extension PatchName: SystemExclusiveData {
    /// Gets the System Exclusive data for this patch name.
    public func asData() -> ByteArray {
        var d = ByteArray()
        for codeUnit in self.value.utf8 {
            d.append(codeUnit)
        }
        return d
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { PatchName.length }
}

// MARK: - CustomStringConvertible

extension PatchName: CustomStringConvertible {
    public var description: String {
        return self.value
    }
}

// MARK: - ExpressibleByStringLiteral

extension PatchName: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = PatchName(value)
    }
}
