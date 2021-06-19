import Foundation

public struct Oscillator: Codable, CustomStringConvertible {
    public var wave: Wave
    public var keyTrack:  Bool
    public var coarse: Int  // -24~+24
    public var fine: Int  // -50~+50
    public var fixedKey: FixedKey  // key represents C-1 to G8
    public var pressureFrequency: Bool
    public var vibrato: Bool
    
    public init() {
        wave = Wave(number: 10)
        keyTrack = true
        coarse = 0
        fine = 0
        fixedKey = FixedKey(key: Byte(FixedKey.keyNumber(for: "C4")))
        pressureFrequency = true
        vibrato = true
    }
    
    public var description: String {
        var lines = [String]()
        
        lines.append("Wave = \(wave.number)  \(wave.name)")
        lines.append("Key track = \(keyTrack)")
        lines.append("Coarse = \(coarse)  Fine = \(fine)")
        lines.append("Fixed key = \(fixedKey)")
        lines.append("Pressure freq. = \(pressureFrequency)")
        lines.append("Vibrato = \(vibrato)")
        return lines.joined(separator: "\n")
    }
    
    public var data: ByteArray {
        var buf = ByteArray()
        
        // s42/s43/s44/s45 key track and coarse
        var s42 = Byte(self.coarse + 24)  // bring into 0~48
        if self.keyTrack {
            s42.setBit(6)
        }
        buf.append(s42)
        
        // s46/s47/s48/s49
        buf.append(self.fixedKey.key)
        
        // s50/s51/s52/s53
        buf.append(Byte(self.fine + 50))
        
        // s54/s55/s56/s57 vel curve, vib/a.bend, prs/freq
        //var s54 = Byte(velocityCurve.rawValue - 1) << 2
        // the velocity curve will be injected later
        var s54: Byte = 0x00
        if self.vibrato {
            s54.setBit(1)
        }
        if self.pressureFrequency {
            s54.setBit(0)
        }
        buf.append(s54)

        return buf
    }
}
