import Foundation

import SyxPack


public protocol SystemExclusiveData {
    func asData() -> ByteArray
}

public struct SystemExclusiveHeader {
    public static let dataSize = 8
    
    public static let initiator: Byte = 0xF0
    public static let terminator: Byte = 0xF7

    public var manufacturerID: Byte
    public var channel: Byte
    public var function: Byte
    public var group: Byte
    public var machineID: Byte
    public var substatus1: Byte
    public var substatus2: Byte
    
    public init() {
        self.manufacturerID = 0
        self.channel = 0
        self.function = 0
        self.group = 0
        self.machineID = 0
        self.substatus1 = 0
        self.substatus2 = 0
    }
    
    public init(d: ByteArray) {
        self.manufacturerID = d[1]
        self.channel = d[2]
        self.function = d[3]
        self.group = d[4]
        self.machineID = d[5]
        self.substatus1 = d[6]
        self.substatus2 = d[7]
    }
    
    public var data: ByteArray {
        return [
            self.manufacturerID,
            self.channel,
            self.function,
            self.group,
            self.machineID,
            self.substatus1,
            self.substatus2
        ]
    }
}

// The Kawai K4 can emit many kinds of System Exclusive dumps,
// with data for one or many singles, multis, etc.
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
    public static func identify(data: ByteArray) -> SystemExclusiveKind? {
        // Extract the SysEx header:
        let headerData = data.slice(from: 0, length: SystemExclusiveHeader.dataSize)
        let header = SystemExclusiveHeader(d: headerData)
        
        // The raw data is everything after the header, not including the very last byte
        let length = data.count - SystemExclusiveHeader.dataSize - 1
        let rawData = data.slice(from: SystemExclusiveHeader.dataSize, length: length)
        
        // Seems like the only way to tell apart one single/multi data dump and
        // one drum/effect data dump is the substatus1 byte in the header.
        // Singles and multis: internal substatus1 = 0x00, external substatus1 = 0x02
        // Drum and effect: internal substatus1 = 0x01, external substatus2 = 0x03

        // Currently we only reliably identify an "all patch data dump".
        switch header.function {
        case 0x20:  // one patch data dump
            switch header.substatus1 {
            case 0...63:
                return .oneSingle(Int(header.substatus1), header.substatus2 == 0x00, rawData)
            case 64...127:
                return .oneMulti(Int(header.substatus1 - 64), header.substatus2 == 0x00, rawData)
            default:
                return nil
            }
        case 0x21:  // block data dump
            switch header.substatus2 {
            case 0x00:
                return .blockSingle(rawData)
            case 0x40:
                return .blockMulti(rawData)
            default:
                return nil
            }
        case 0x22:  // all data dump
            return .all(header.substatus2 == 0x00, rawData)
        default:
            return nil
        }
    }
}
