import Foundation

/// Type of effect.
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

public struct EffectName {
    public var name: String
    public var parameters: [String]
}

public let effectParameterNames: [Effect: EffectName] = [
    .undefined: EffectName(
        name: "unknown",
        parameters: ["unknown", "unknown", "unknown"]),
    .reverb1: EffectName(
        name: "Reverb 1",
        parameters: ["Pre. Delay", "Rev. Time", "Tone"]),
    .reverb2: EffectName(
        name: "Reverb 2",
        parameters: ["Pre. Delay", "Rev. Time", "Tone"]),
    .reverb3: EffectName(
        name: "Reverb 3",
        parameters: ["Pre. Delay", "Rev. Time", "Tone"]),
    .reverb4: EffectName(
        name: "Reverb 4",
        parameters: ["Pre. Delay", "Rev. Time", "Tone"]),
    .gateReverb: EffectName(
        name: "Gate Reverb",
        parameters: ["Pre. Delay", "Gate Time", "Tone"]),
    .reverseGate: EffectName(
        name: "Reverse Gate",
        parameters: ["Pre. Delay", "Gate Time", "Tone"]),
    .normalDelay: EffectName(
        name: "Normal Delay",
        parameters: ["Feed back", "Tone", "Delay"]),
    .stereoPanpotDelay: EffectName(
        name: "Stereo Panpot Delay",
        parameters: ["Feed back", "L/R Delay", "Delay"]),
    .chorus: EffectName(
        name: "Chorus",
        parameters: ["Width", "Feed back", "Rate"]),
    .overdrivePlusFlanger: EffectName(
        name: "Overdrive + Flanger",
        parameters: ["Drive", "Fl. Type", "1-2 Bal"]),
    .overdrivePlusNormalDelay: EffectName(
        name: "Overdrive + Normal Delay",
        parameters: ["Drive", "Delay Time", "1-2 Bal"]),
    .overdrivePlusReverb: EffectName(
        name: "Overdrive + Reverb",
        parameters: ["Drive", "Rev. Type", "1-2 Bal"]),
    .normalDelayPlusNormalDelay: EffectName(
        name: "Normal Delay + Normal Delay",
        parameters: ["Delay1", "Delay2", "1-2 Bal"]),
    .normalDelayPlusStereoPanpotDelay: EffectName(
        name: "Normal Delay + Stereo Pan.Delay",
        parameters: ["Delay1", "Delay2", "1-2 Bal"]),
    .chorusPlusNormalDelay: EffectName(
        name: "Chorus + Normal Delay",
        parameters: ["Chorus", "Delay", "1-2 Bal"]),
    .chorusPlusStereoPanpotDelay: EffectName(
        name: "Chorus + Stereo Pan Delay",
        parameters: ["Chorus", "Delay", "1-2 Bal"]),
]

public struct SubmixSettings: Codable, CustomStringConvertible {
    public var pan: Int  // 0~15 / 0~+/-7 (K4)
    public var send1: Int  // 0~99
    public var send2: Int  // 0~100 (from correction sheet, not 0~99)
    
    public init() {
        self.pan = 0
        self.send1 = 0
        self.send2 = 0
    }
    
    public init(pan: Int, send1: Int, send2: Int) {
        self.pan = pan
        self.send1 = send1
        self.send2 = send2
    }
    
    public var data: ByteArray {
        return [Byte(pan + 8), Byte(send1), Byte(send2)]
    }
    
    public var description: String {
        return "Pan=\(pan) Send1=\(send1) Send2=\(send2)"
    }
}

/// Represents an effect patch.
public struct EffectPatch: Codable, CustomStringConvertible {
    static let dataSize = 35
    static let submixCount = 8
    
    public var effect: Effect
    public var param1: Int  // 0~7
    public var param2: Int  // 0~7
    public var param3: Int  // 0~31
    public var submixes: [SubmixSettings]
    
    public init() {
        effect = .reverb1
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
        var offset = 0
        var b: Byte = 0

        //print("effect:\n\(buffer.hexDump)")
        
        b = buffer.next(&offset)
        effect = Effect(index: Int(b + 1))!
        
        b = buffer.next(&offset)
        param1 = Int(b)
        
        b = buffer.next(&offset)
        param2 = Int(b)
        
        b = buffer.next(&offset)
        param3 = Int(b)
        
        offset += 6 // skip dummy bytes
        
        self.submixes = [SubmixSettings]()
        for _ in 0..<EffectPatch.submixCount {
            b = buffer.next(&offset)
            let pan = Int(b) - 7

            b = buffer.next(&offset)
            let send1 = Int(b)

            b = buffer.next(&offset)
            let send2 = Int(b)

            let submix = SubmixSettings(pan: pan, send1: send1, send2: send2)
            submixes.append(submix)
        }
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        [effect.index!, param1, param2, param3, 0, 0, 0, 0, 0, 0].forEach {
            buf.append(Byte($0))
        }
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
    
    public var description: String {
        var lines = [String]()
        if let name = effectParameterNames[self.effect] {
            lines.append("\(name.name): \(name.parameters[0])=\(self.param1)  \(name.parameters[1])=\(self.param2)  \(name.parameters[2])=\(self.param3)")
        }
        for (index, submixSettings) in submixes.enumerated() {
            let submix = Submix(index: index)!
            lines.append("  \(submix.rawValue.uppercased()): \(submixSettings)")
        }
        return lines.joined(separator: "\n")
    }
}
