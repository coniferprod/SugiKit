import Foundation

public struct SystemExclusiveHeader {
    static let dataSize = 8
    
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
    
    public init(d: Data) {
        self.manufacturerID = d[1]
        self.channel = d[2]
        self.function = d[3]
        self.group = d[4]
        self.machineID = d[5]
        self.substatus1 = d[6]
        self.substatus2 = d[7]
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        buf.append(contentsOf: [
            self.manufacturerID,
            self.channel,
            self.function,
            self.group,
            self.machineID,
            self.substatus1,
            self.substatus2
        ])
        
        return buf
    }
}
