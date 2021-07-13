import Foundation

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
    case all(ByteArray)
    case oneSingle(ByteArray)
    case oneMulti(ByteArray)
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
        
        // TODO: determine the kind from the header
        
        return nil
    }
}
