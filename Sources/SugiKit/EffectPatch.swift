import Foundation

import SyxPack


/// The effect type.
public enum Effect: String, Codable, CaseIterable {
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
    
    public struct Name: Codable {
        public var name: String
        public var parameters: [String]
    }
    
    public static let names = [Name]([
        Name(
            name: "unknown",
            parameters: ["unknown", "unknown", "unknown"]),
        Name(
            name: "Reverb 1",
            parameters: ["Pre. Delay", "Rev. Time", "Tone"]),
        Name(
            name: "Reverb 2",
            parameters: ["Pre. Delay", "Rev. Time", "Tone"]),
        Name(
            name: "Reverb 3",
            parameters: ["Pre. Delay", "Rev. Time", "Tone"]),
        Name(
            name: "Reverb 4",
            parameters: ["Pre. Delay", "Rev. Time", "Tone"]),
        Name(
            name: "Gate Reverb",
            parameters: ["Pre. Delay", "Gate Time", "Tone"]),
        Name(
            name: "Reverse Gate",
            parameters: ["Pre. Delay", "Gate Time", "Tone"]),
        Name(
            name: "Normal Delay",
            parameters: ["Feed back", "Tone", "Delay"]),
        Name(
            name: "Stereo Panpot Delay",
            parameters: ["Feed back", "L/R Delay", "Delay"]),
        Name(
            name: "Chorus",
            parameters: ["Width", "Feed back", "Rate"]),
        Name(
            name: "Overdrive + Flanger",
            parameters: ["Drive", "Fl. Type", "1-2 Bal"]),
        Name(
            name: "Overdrive + Normal Delay",
            parameters: ["Drive", "Delay Time", "1-2 Bal"]),
        Name(
            name: "Overdrive + Reverb",
            parameters: ["Drive", "Rev. Type", "1-2 Bal"]),
        Name(
            name: "Normal Delay + Normal Delay",
            parameters: ["Delay1", "Delay2", "1-2 Bal"]),
        Name(
            name: "Normal Delay + Stereo Pan.Delay",
            parameters: ["Delay1", "Delay2", "1-2 Bal"]),
        Name(
            name: "Chorus + Normal Delay",
            parameters: ["Chorus", "Delay", "1-2 Bal"]),
        Name(
            name: "Chorus + Stereo Pan Delay",
            parameters: ["Chorus", "Delay", "1-2 Bal"]),
    ])
}

public struct SubmixSettings: Codable, Equatable {
    public var pan: Int  // 0~15 / 0~+/-7 (K4)
    public var send1: UInt  // 0~99
    public var send2: UInt  // 0~100 (from correction sheet, not 0~99)
    
    public init() {
        self.pan = 0
        self.send1 = 0
        self.send2 = 0
    }
    
    public init(pan: Int, send1: UInt, send2: UInt) {
        self.pan = pan
        self.send1 = send1
        self.send2 = send2
    }
    
    public var data: ByteArray {
        return [Byte(pan + 8), Byte(send1), Byte(send2)]
    }
}

/// Represents an effect patch.
public class EffectPatch: HashableClass, Codable, Identifiable {
    static let dataSize = 35
    static let submixCount = 8
    
    public var effect: Effect
    public var param1: Int  // 0~7
    public var param2: Int  // 0~7
    public var param3: Int  // 0~31
    public var submixes: [SubmixSettings]
    
    public override init() {
        effect = .reverb1
        param1 = 0
        param2 = 3
        param3 = 16
        submixes = Array(repeating: SubmixSettings(pan: 0, send1: 50, send2: 50), count: EffectPatch.submixCount)
    }
    
    /// Parse effect patch data from MIDI System Exclusive data bytes.
    /// - Parameter data: The data bytes.
    /// - Returns: A result type with valid `EffectPatch` data or an instance of `ParseError`.
    public static func parse(from data: ByteArray) -> Result<EffectPatch, ParseError> {
        guard data.count >= EffectPatch.dataSize else {
            return .failure(.notEnoughData(data.count, EffectPatch.dataSize))
        }
        
        var offset = 0
        var b: Byte = 0

        var temp = EffectPatch()  // init with defaults, then fill in
        
        b = data.next(&offset)
        temp.effect = Effect(index: Int(b + 1))!  // in SysEx 0~15, store as 1~16
        
        b = data.next(&offset)
        temp.param1 = Int(b)
        
        b = data.next(&offset)
        temp.param2 = Int(b)
        
        b = data.next(&offset)
        temp.param3 = Int(b)
        
        offset += 6 // skip dummy bytes
        
        temp.submixes = [SubmixSettings]()
        for _ in 0..<EffectPatch.submixCount {
            b = data.next(&offset)
            let pan = Int(b) - 7

            b = data.next(&offset)
            let send1 = UInt(b)

            b = data.next(&offset)
            let send2 = UInt(b)

            let submix = SubmixSettings(pan: pan, send1: send1, send2: send2)
            temp.submixes.append(submix)
        }
        
        return .success(temp)
    }

    public var data: ByteArray {
        var buf = ByteArray()
        [effect.index - 1, param1, param2, param3, 0, 0, 0, 0, 0, 0].forEach {
            buf.append(Byte($0))
        }
        self.submixes.forEach { buf.append(contentsOf: $0.data) }
        return buf
    }    
}

// MARK: - SystemExclusiveData

extension EffectPatch: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { EffectPatch.dataSize }
}

// MARK: - CustomStringConvertible

extension EffectPatch: CustomStringConvertible {
    public var description: String {
        var lines = [String]()
        let name = Effect.names[self.effect.index]
        lines.append("\(name.name): \(name.parameters[0])=\(self.param1)  \(name.parameters[1])=\(self.param2)  \(name.parameters[2])=\(self.param3)")
        for (index, submixSettings) in submixes.enumerated() {
            let submix = Submix(index: index)!
            lines.append("  \(submix.rawValue.uppercased()): \(submixSettings)")
        }
        return lines.joined(separator: "\n")
    }
}

extension SubmixSettings: CustomStringConvertible {
    public var description: String {
        return "Pan=\(pan) Send1=\(send1) Send2=\(send2)"
    }
}
