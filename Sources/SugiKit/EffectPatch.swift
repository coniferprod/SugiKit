import Foundation

import SyxPack


/// The effect type.
public enum Effect: Int, Codable, CaseIterable {
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
    
    /// Initializes an effect from raw value.
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
    
    /// Gets the effect name.
    public var name: String {
        return Effect.names[self.rawValue].name
    }
    
    /// Helper struct with the effect name and the names of its parameters.
    public struct Name: Codable {
        /// Effect name
        public var name: String
        
        /// Effect parameters names
        public var parameters: [String]
    }
    
    /// Proprety to access effect names by effect number.
    /// Indexed by effect number 1...16, so that index 0 is unused.
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

/// Effect submix settings.
public struct SubmixSettings: Equatable {
    /// Compares two submix setting instances.
    /// - Parameter lhs: left-hand side
    /// - Parameter rgs: right-hand side
    public static func == (lhs: SubmixSettings, rhs: SubmixSettings) -> Bool {
        return lhs.pan == rhs.pan && lhs.send1 == rhs.send1 && lhs.send2 == rhs.send2
    }
    
    /// Data size of submix settings.
    public static let dataSize = 3
    
    public var pan: Pan  // 0~15 / 0~+/-7 (K4)
    public var send1: Send1  // 0~99
    public var send2: Send2  // 0~100 (from correction sheet, not 0~99)

    /// Initializes submix settings to default values.
    public init() {
        self.pan = Pan(0)
        self.send1 = Send1(0)
        self.send2 = Send2(0)
    }
    
    /// Initializes submix settings with the specified values.
    /// - Parameter pan: the pan value
    /// - Parameter send1: the send 1 value
    /// - Parameter send2: the send 2 value
    public init(pan: Int, send1: Int, send2: Int) {
        self.pan = Pan(pan)
        self.send1 = Send1(send1)
        self.send2 = Send2(send2)
    }
}

/// Represents an effect patch.
public class EffectPatch: HashableClass, Identifiable {
    public static let dataSize = 35
    public static let submixCount = 8
    
    public var effect: Effect
    public var param1: EffectParameterSmall  // 0~7
    public var param2: EffectParameterSmall  // 0~7
    public var param3: EffectParameterLarge  // 0~31
    public var submixes: [SubmixSettings]
    
    /// Initializes an effect patch with default settings.
    public override init() {
        effect = .reverb1
        param1 = EffectParameterSmall(0)
        param2 = EffectParameterSmall(3)
        param3 = EffectParameterLarge(16)
        submixes = Array(
            repeating: SubmixSettings(pan: 0, send1: 50, send2: 50),
            count: EffectPatch.submixCount
        )
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
        temp.param1 = EffectParameterSmall(Int(b))
        
        b = data.next(&offset)
        temp.param2 = EffectParameterSmall(Int(b))
        
        b = data.next(&offset)
        temp.param3 = EffectParameterLarge(Int(b))
        
        offset += 6 // skip dummy bytes
        
        temp.submixes = [SubmixSettings]()
        for _ in 0..<EffectPatch.submixCount {
            b = data.next(&offset)
            let pan = Int(b) - 7

            b = data.next(&offset)
            let send1 = Int(b)

            b = data.next(&offset)
            let send2 = Int(b)

            let submix = SubmixSettings(pan: pan, send1: send1, send2: send2)
            temp.submixes.append(submix)
        }
        
        return .success(temp)
    }

    private var data: ByteArray {
        var buf = ByteArray()
        [effect.index - 1, param1.value, param2.value, param3.value,
            0, 0, 0, 0, 0, 0].forEach {
            buf.append(Byte($0))
        }
        self.submixes.forEach { buf.append(contentsOf: $0.asData()) }
        return buf
    }    
}

// MARK: - SystemExclusiveData

extension EffectPatch: SystemExclusiveData {
    /// Gets the System Exclusive data for the effect patch.
    /// - Returns: A byte array with the data
    public func asData() -> ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { EffectPatch.dataSize }
}

extension SubmixSettings: SystemExclusiveData {
    /// Gets the System Exclusive data for the submix settings.
    /// - Returns: A byte array with the data
    public func asData() -> ByteArray {
        return [Byte(pan.value + 8), Byte(send1.value), Byte(send2.value)]  // TODO: or +7?
    }
    
    /// Gets the length of the System Exclusive data.
    public var dataLength: Int { SubmixSettings.dataSize }
}

// MARK: - CustomStringConvertible

extension Effect: CustomStringConvertible {
    /// A printable description of the effect.
    public var description: String {
        return self.name
    }
}

extension EffectPatch: CustomStringConvertible {
    /// A printable description of the effect patch.
    public var description: String {
        var lines = [String]()
        let name = Effect.names[self.effect.index]
        lines.append("\(name.name): \(name.parameters[0])=\(self.param1.value)  \(name.parameters[1])=\(self.param2.value)  \(name.parameters[2])=\(self.param3.value)")
        for (index, submixSettings) in submixes.enumerated() {
            let submix = Submix(index: index)!
            lines.append("  \(submix.rawValue.uppercased()): \(submixSettings)")
        }
        return lines.joined(separator: "\n")
    }
}

extension SubmixSettings: CustomStringConvertible {
    /// A printable description of the submix settings
    public var description: String {
        return "Pan=\(pan.value) Send1=\(send1.value) Send2=\(send2.value)"
    }
}
