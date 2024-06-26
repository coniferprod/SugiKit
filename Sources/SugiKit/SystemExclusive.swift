import Foundation

import ByteKit
import SyxPack


/// The Kawai K4 System Exclusive message header.
public struct Header {
    /// The data size of a System Exclusive message header.
    public static let dataSize = 6

    /// Identifier for synth group (Kawai)
    public static let group: Byte = 0x00 // synth group = 0x00
    
    /// Identifier for machine (Kawai K4/K4r)
    public static let machineID: Byte = 0x04 // machine ID for K4/K4r

    public var channel: MIDIChannel
    public var function: Function
    public var substatus1: Byte
    public var substatus2: Byte

    /// Initializes a header with default values.
    public init() {
        self.channel = 1
        self.function = .onePatchDataDump
        self.substatus1 = 0x00
        self.substatus2 = 0x00
    }

    /// Initializes a header with the specified values.
    /// - Parameter channel: the MIDI channel to use
    /// - Parameter function: the Kawai K4 function to use
    /// - Parameter substatus1: the sub status 1 byte
    /// - Parameter substatus2: the sub status 2 byte
    public init(channel: Int, function: Function, substatus1: Byte, substatus2: Byte) {
        self.channel = MIDIChannel(channel)
        self.function = function
        self.substatus1 = substatus1
        self.substatus2 = substatus2
    }
    
    private var data: ByteArray {
        return [
            Byte(self.channel.value - 1),  // adjust back to 0...15 for SysEx
            self.function.rawValue,
            Header.group,
            Header.machineID,
            self.substatus1,
            self.substatus2
        ]
    }
    
    /// Parse System Exclusive header from data bytes.
    /// - Parameter data: The data bytes.
    /// - Returns: A result type with a valid `Header`, or an instance of `ParseError`.
    public static func parse(from data: ByteArray) -> Result<Header, ParseError> {
        var temp = Header()
        
        temp.channel = MIDIChannel(Int(data[0] + 1))  // adjust to 1...16
        
        if let fn = Function(index: Int(data[1])) {
            temp.function = fn
        }
        else {
            return .failure(.invalidData(1))
        }

        let ok = (data[2] == Header.group && data[3] == Header.machineID)
        if !ok {
            return .failure(.invalidData(2))
        }
        
        temp.substatus1 = data[4]
        temp.substatus2 = data[5]
        
        return .success(temp)
    }
}

extension Header: CustomStringConvertible {
    /// Printable description of the System Exclusive header.
    public var description: String {
        return "Ch: \(channel.value)  Fn: \(function.rawValue.toHexString()), Sub1: \(substatus1.toHexString()) Sub2: \(substatus2.toHexString())"
    }
}

extension Header: SystemExclusiveData {
    /// Gets the System Exclusive data for the header as a byte array.
    public func asData() -> ByteArray {
        return self.data
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { Header.dataSize }
}

/// Represents a Kawai K4 System Exclusive function.
public enum Function: Byte {
    case onePatchDumpRequest = 0x00
    case blockPatchDumpRequest = 0x01
    case allPatchDumpRequest = 0x02
    case parameterSend = 0x10
    case onePatchDataDump = 0x20
    case blockPatchDataDump = 0x21
    case allPatchDataDump = 0x22
    case editBufferDump = 0x23
    case programChange = 0x30
    case writeComplete = 0x40
    case writeError = 0x41
    case writeErrorProtect = 0x42
    case writeErrorNoCard = 0x43
    
    /// Initializes a function from an index. Returns `nil` if the index does not match any enum case.
    public init?(index: Int) {
        switch index {
        case 0x00: self = .onePatchDumpRequest
        case 0x01: self = .blockPatchDumpRequest
        case 0x02: self = .allPatchDumpRequest
        case 0x10: self = .parameterSend
        case 0x20: self = .onePatchDataDump
        case 0x21: self = .blockPatchDataDump
        case 0x22: self = .allPatchDataDump
        case 0x23: self = .editBufferDump
        case 0x30: self = .programChange
        case 0x40: self = .writeComplete
        case 0x41: self = .writeError
        case 0x42: self = .writeErrorProtect
        case 0x43: self = .writeErrorNoCard
        default: return nil
        }
    }
}

extension Function: CustomStringConvertible {
    /// Printable description for the Kawai K4 function.
    public var description: String {
        switch self {
        case .onePatchDumpRequest:
            return "One Patch Dump Request"
        case .blockPatchDumpRequest:
            return "Block Patch Dump Request"
        case .allPatchDumpRequest:
            return "All Patch Dump Request"
        case .parameterSend:
            return "Parameter Send"
        case .onePatchDataDump:
            return "One Patch Data Dump"
        case .blockPatchDataDump:
            return "Block Patch Data Dump"
        case .allPatchDataDump:
            return "All Patch Data Dump"
        case .editBufferDump:
            return "Edit Buffer Dump"
        case .programChange:
            return "Program Change"
        case .writeComplete:
            return "Write Complete"
        case .writeError:
            return "Write Error"
        case .writeErrorProtect:
            return "Write Error (Protect)"
        case .writeErrorNoCard:
            return "Write Error (No Card)"
        }
    }
}

/// The locality of the data (internal or external).
public enum Locality {
    case `internal`  // must enclose in quotes because it is a Swift keyword
    case external
}

extension Locality: CustomStringConvertible {
    /// Printable description of the locality.
    public var description: String {
        switch self {
        case .internal:
            return "INT"
        case .external:
            return "EXT"
        }
    }
}

/// Represents the kind of Kawai K4 MIDI System Exclusive dump.
public enum SystemExclusiveKind {
    case all(Locality, ByteArray)
    
    // Int: number for single A-1 ~ D-16
    // Locality: INT or EXT
    // ByteArray: the raw data
    case oneSingle(Int, Locality, ByteArray)
    
    // Int: number for multi A-1 ~ D-16
    // Locality: INT or EXT
    // ByteArray: the raw data
    case oneMulti(Int, Locality, ByteArray)
    
    case drum(Locality, ByteArray)
    case oneEffect(Int, Locality, ByteArray)
    case blockSingle(Locality, ByteArray)
    case blockMulti(Locality, ByteArray)
    case blockEffect(Locality, ByteArray)
    
    /// Identifies the SysEx message and returns the corresponding
    /// enumeration value with the raw data.
    public static func identify(payload: Payload) -> Result<SystemExclusiveKind, ParseError> {
        // Extract the SysEx header from the message payload:
        let headerData = payload.slice(from: 0, length: Header.dataSize)
        switch Header.parse(from: headerData) {
        case .success(let header):
            // The raw data is everything in the payload after the header.
            let rawData = ByteArray(payload.suffix(from: Header.dataSize))
            
            // Header substatus1 values:
            // 0x00 = INT for single/multi or program change
            // 0x02 = EXT for single/multi or program change
            // 0x01 = INT for drum/effect
            // 0x03 = EXT for drum/effect
            
            // Header substatus2 values:
            // For single/multi: 0...63 = single, 64...127 = multi
            // For drum/effect: 0...31 = effect, 32 = drum
            // For block dump: 0x00 = all singles, 0x40 = all multis / all effects
            
            switch (header.function, header.substatus1, header.substatus2) {
            case (.onePatchDataDump, 0x00, let number) where (0...63).contains(number):
                return .success(.oneSingle(Int(number), .internal, rawData))
            case (.onePatchDataDump, 0x00, let number) where (64...127).contains(number):
                return .success(.oneMulti(Int(number), .internal, rawData))
            case (.onePatchDataDump, 0x02, let number) where (0...63).contains(number):
                return .success(.oneSingle(Int(number), .external, rawData))
            case (.onePatchDataDump, 0x02, let number) where (64...127).contains(number):
                return .success(.oneMulti(Int(number), .external, rawData))
            case (.onePatchDataDump, 0x01, let number) where (0...31).contains(number):
                return .success(.oneEffect(Int(number), .internal, rawData))
            case (.onePatchDataDump, 0x03, let number) where (0...31).contains(number):
                return .success(.oneEffect(Int(number), .external, rawData))
            case (.onePatchDataDump, 0x01, let number) where number == 32:
                return .success(.drum(.internal, rawData))
            case (.onePatchDataDump, 0x03, let number) where number == 32:
                return .success(.drum(.external, rawData))
            case (.blockPatchDataDump, 0x00, 0x00):
                return .success(.blockSingle(.internal, rawData))
            case (.blockPatchDataDump, 0x00, 0x40):
                return .success(.blockMulti(.internal, rawData))
            case (.blockPatchDataDump, 0x02, 0x00):
                return .success(.blockSingle(.external, rawData))
            case (.blockPatchDataDump, 0x02, 0x40):
                return .success(.blockMulti(.external, rawData))
            case (.blockPatchDataDump, 0x01, 0x00):
                return .success(.blockEffect(.internal, rawData))
            case (.blockPatchDataDump, 0x03, 0x00):
                return .success(.blockEffect(.external, rawData))
            case (.allPatchDataDump, 0x00, 0x00):
                return .success(.all(.internal, rawData))
            case (.allPatchDataDump, 0x02, 0x00):
                return .success(.all(.external, rawData))
            default:
                return .failure(.unidentified)
            }

        case .failure(let error):
            return .failure(error)
        }
    }
}

extension SystemExclusiveKind: CustomStringConvertible {
    /// Printable description of the System Exclusive kind.
    public var description: String {
        switch self {
        case .all(let locality, _):
            return "Bank \(locality)"
        case .oneSingle(let number, let locality, _):
            return "Single \(Bank.nameFor(patchNumber: number)) \(locality)"
        case .oneMulti(let number, let locality, _):
            return "Multi \(Bank.nameFor(patchNumber: number)) \(locality)"
        case .drum(let locality, _):
            return "Drum \(locality)"
        case .oneEffect(let number, let locality, _):
            return "Effect \(number + 1) \(locality)"
        case .blockSingle(let locality, _):
            return "Block Single \(locality)"
        case .blockMulti(let locality, _):
            return "Block Multi \(locality)"
        case .blockEffect(let locality, _):
            return "Block Effect \(locality)"
        }
    }
}
