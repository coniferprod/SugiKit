import Foundation

import SyxPack


/// Protocol for getting the MIDI System Exclusive data bytes of an item.
public protocol SystemExclusiveData {
    func asData() -> ByteArray
}

/// Represents a Kawai K4/K4r System Exclusive message header.
public struct SugiMessage {
    public struct Header {
        public static let dataSize = 8

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
            self.channel = Int(d[2] + 1)  // adjust to 1...16
            self.function = d[3]
            self.group = d[4]
            self.machineID = d[5]
            self.substatus1 = d[6]
            self.substatus2 = d[7] // always zero for K4
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
    
    public var header: Header
    public var content: ByteArray

    // For a SyxPack message, the payload is header + content.
    // The content is the result of asData() from SinglePatch, MultiPatch,
    // Drum, Effect, or Bank. It already has the necessary checksum.
    // So the final MIDI SysEx message the bytes of a SyxPack manufacturer-specific message as below:

    /// Constructs the bytes of a manufacturer-specific System Exclusive message for Kawai from a SugiMessage.
    /// The result is ready to be sent down to a MIDI output port or saved to a file.
    public func asBytes() -> ByteArray {
        return Message.manufacturerSpecific(Manufacturer.kawai, self.asData()).asData()
    }
}

extension SugiMessage: SystemExclusiveData {
    public func asData() -> ByteArray {
        var result = ByteArray()
        result.append(contentsOf: self.header.data)
        result.append(contentsOf: self.content)
        return result
    }
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
    public static func identify(data: ByteArray) -> SystemExclusiveKind? {
        // Extract the SysEx header:
        let headerData = data.slice(from: 0, length: SugiMessage.Header.dataSize)
        let header = SugiMessage.Header(d: headerData)
        
        // The raw data is everything after the header, not including the very last byte
        let length = data.count - SugiMessage.Header.dataSize - 1
        let rawData = data.slice(from: SugiMessage.Header.dataSize, length: length)
        
        // Seems like the only way to tell apart one single/multi data dump and
        // one drum/effect data dump is the substatus1 byte in the header.
        // Singles and multis: internal substatus1 = 0x00, external substatus1 = 0x02
        // Drum and effect: internal substatus1 = 0x01, external substatus1 = 0x03

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
