import Foundation

import SyxPack


public struct Header {
    public static let dataSize = 6

    public var channel: Int  // pass it in as 1...16
    public var function: Byte
    public var group: Byte
    public var machineID: Byte
    public var substatus1: Byte
    public var substatus2: Byte

    public init(channel: Int, function: Byte, substatus1: Byte) {
        self.channel = channel
        self.function = function
        self.group = 0x00  // synth group = 0x00
        self.machineID = 0x04 // machine ID for K4/K4r
        self.substatus1 = substatus1
        self.substatus2 = 0x00 // always zero for K4
    }
    
    public init(d: ByteArray) {
        self.channel = Int(d[0] + 1)  // adjust to 1...16
        self.function = d[1]
        self.group = d[2]
        self.machineID = d[3]
        self.substatus1 = d[4]
        self.substatus2 = d[5] // always zero for K4
    }

    public var data: ByteArray {
        return [
            Byte(self.channel - 1),  // adjust back to 0...15 for SysEx
            self.function,
            self.group,
            self.machineID,
            self.substatus1,
            self.substatus2
        ]
    }
}

extension Header: CustomStringConvertible {
    public var description: String {
        return "Ch: \(channel)  Fn: \(function.toHex()), Sub1: \(substatus1.toHex()) Sub2: \(substatus2.toHex())"
    }
}

extension Header: SystemExclusiveData {
    /// Gets the data as a byte array.
    public func asData() -> ByteArray {
        return self.data
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { Header.dataSize }
}

/// Represents the kind of Kawai K4 MIDI System Exclusive dump.
public enum SystemExclusiveKind {
    case all(Bool, ByteArray)
    
    // Int: number for single A-1 ~ D-16
    // Bool: true if internal, false if external
    // ByteArray: the raw data
    case oneSingle(Int, Bool, ByteArray)
    
    // Int: number for multi A-1 ~ D-16
    // Bool: true if internal, false if external
    // ByteArray: the raw data
    case oneMulti(Int, Bool, ByteArray)
    
    case drum(ByteArray)
    case oneEffect(ByteArray)
    case blockSingle(ByteArray)
    case blockMulti(ByteArray)
    case blockEffect(ByteArray)
    
    /// Identifies the SysEx message and returns the corresponding
    /// enumeration value with the raw data.
    public static func identify(payload: Payload) -> Result<SystemExclusiveKind, ParseError> {
        // Extract the SysEx header from the message payload:
        let headerData = payload.slice(from: 0, length: Header.dataSize)
        let header = Header(d: headerData)
        
        // The raw data is everything in the payload after the header.
        let rawData = ByteArray(payload.suffix(from: Header.dataSize))
        
        // Seems like the only way to tell apart one single/multi data dump and
        // one drum/effect data dump is the substatus1 byte in the header.
        // Singles and multis: internal substatus1 = 0x00, external substatus1 = 0x02
        // Drum and effect: internal substatus1 = 0x01, external substatus1 = 0x03

        switch header.function {
        case 0x20:  // one patch data dump
            switch header.substatus1 {
            case 0...63:
                return .success(.oneSingle(Int(header.substatus1), header.substatus2 == 0x00, rawData))
            case 64...127:
                return .success(.oneMulti(Int(header.substatus1 - 64), header.substatus2 == 0x00, rawData))
            default:
                return .failure(.unidentified)
            }
        case 0x21:  // block data dump
            switch header.substatus2 {
            case 0x00:
                return .success(.blockSingle(rawData))
            case 0x40:
                return .success(.blockMulti(rawData))
            default:
                return .failure(.unidentified)
            }
        case 0x22:  // all data dump
            return .success(.all(header.substatus2 == 0x00, rawData))
        default:
            return .failure(.unidentified)
        }
    }
}

extension SystemExclusiveKind: CustomStringConvertible {
    private func getLocality(_ isInternal: Bool) -> String {
        return isInternal ? "INT" : "EXT"
    }
    
    public var description: String {
        switch self {
        case .all(let isInternal, _):
            return "Bank \(getLocality(isInternal))"
        case .oneSingle(let number, let isInternal, _):
            return "Single \(PatchName.bankNameForNumber(n: number)) \(getLocality(isInternal))"
        case .oneMulti(let number, let isInternal, _):
            return "Multi \(PatchName.bankNameForNumber(n: number)) \(getLocality(isInternal))"
        case .drum:
            return "Drum"
        case .oneEffect( _):
            return "Effect"
        case .blockSingle(_):
            return "Block Single"
        case .blockMulti(_):
            return "Block Multi"
        case .blockEffect(_):
            return "Block Effect"
        }
    }
}
