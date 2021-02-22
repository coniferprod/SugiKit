import Foundation

/// Type of effect.
public enum EffectType: String, Codable, CaseIterable {
    case undefined
    case reverb1
    case reverb2
    case reverb3
    case reverb4
    case gateReverb
    case reverseGate
    case normalDelay
    case stereoPanpotDelay
    case chorus
    case overdrivePlusFlanger
    case overdrivePlusNormalDelay
    case overdrivePlusReverb
    case normalDelayPlusNormalDelay
    case normalDelayPlusStereoPanpotDelay
    case chorusPlusNormalDelay
    case chorusPlusStereoPanpotDelay
    
    init?(index: Int) {
        switch index {
        case 0: self = .undefined
        case 1: self = .reverb1
        case 2: self = .reverb2
        case 3: self = .reverb3
        case 4: self = .reverb4
        case 5: self = .gateReverb
        case 6: self = .reverseGate
        case 7: self = .normalDelay
        case 8: self = .stereoPanpotDelay
        case 9: self = .chorus
        case 10: self = .overdrivePlusFlanger
        case 11: self = .overdrivePlusNormalDelay
        case 12: self = .overdrivePlusReverb
        case 13: self = .normalDelayPlusNormalDelay
        case 14: self = .normalDelayPlusStereoPanpotDelay
        case 15: self = .chorusPlusNormalDelay
        case 16: self = .chorusPlusStereoPanpotDelay
        default: return nil
        }
    }
}

public struct SubmixSettings: Codable {
    public var pan: Int  // 0~15 / 0~+/-7 (K4)
    public var send1: Int
    public var send2: Int
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        buf.append(Byte(self.pan + 8))
        buf.append(Byte(self.send1))
        buf.append(Byte(self.send2))
        
        return buf
    }
}

/// Represents an effect patch.
public struct EffectPatch: Codable {
    static let dataSize = 35
    
    public var effectType: EffectType
    public var param1: Int
    public var param2: Int
    public var param3: Int
    public var submixes: [SubmixSettings]
    
    public init() {
        effectType = .reverb1
        param1 = 0
        param2 = 3
        param3 = 16
        submixes = [
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50)
        ]
    }
    
    public init(bytes buffer: ByteArray) {
        // Parse later, just init for now
        effectType = .reverb1
        param1 = 0
        param2 = 3
        param3 = 16
        submixes = [
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50),
            SubmixSettings(pan: 0, send1: 50, send2: 50)
        ]
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        buf.append(contentsOf: [
            Byte(effectType.index!),
            Byte(param1),
            Byte(param2),
            Byte(param3),
            0, 0, 0, 0, 0, 0
        ])

        self.submixes.forEach { buf.append(contentsOf: $0.data) }
    
        return buf
    }
    
    public var systemExclusiveData: ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }
}
