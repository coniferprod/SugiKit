#if os(Linux)
import Glibc
#else
import Darwin
#endif

import ByteKit
import SyxPack

struct StandardErrorOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

var standardError = StandardErrorOutputStream()

struct SugiKit {
    var text = "SugiKit"
}

/// Error type for parsing data from MIDI System Exclusive bytes.
public enum ParseError: Error {
    case notEnoughData(Int, Int)  // actual, expected
    case badChecksum(Byte, Byte)  // actual, expected
    case invalidData(Int)  // offset in data
    case unidentified  // can't identify this kind
}

extension ParseError: CustomStringConvertible {
    /// Gets a printable description of this parse error.
    public var description: String {
        switch self {
        case .notEnoughData(let actual, let expected):
            return "Got \(actual) bytes of data, expected \(expected) bytes."
        case .badChecksum(let actual, let expected):
            return "Computed checksum was \(actual.toHexString())H, expected \(expected.toHexString())H."
        case .invalidData(let offset):
            return "Invalid data at offset \(offset)."
        case .unidentified:
            return "Unable to identify this System Exclusive file."
        }
    }
}
