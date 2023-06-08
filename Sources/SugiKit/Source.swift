import Foundation

import SyxPack


/// Represents one source in a single patch.
public struct Source: Codable {
    static let dataSize = 7

    public var isActive: Bool
    public var delay: Int // 0~100
    public var wave: Wave
    public var keyTrack:  Bool
    public var coarse: Int  // -24~+24
    public var fine: Int  // -50~+50
    public var fixedKey: FixedKey  // key represents C-1 to G8
    public var pressureFrequency: Bool
    public var vibrato: Bool
    public var velocityCurve: VelocityCurve
    public var keyScalingCurve: KeyScalingCurve
    
    /// Initializes the source with default settings.
    public init() {
        isActive = false
        delay = 0
        wave = Wave(number: 10)
        keyTrack = true
        coarse = 0
        fine = 0
        fixedKey = FixedKey(key: Byte(FixedKey.keyNumber(for: "C4")))
        pressureFrequency = true
        vibrato = true
        velocityCurve = .curve1
        keyScalingCurve = .curve1
    }

    /// Parses a single patch source from MIDI System Exclusive data bytes.
    public static func parse(from data: ByteArray) -> Result<Source, ParseError> {
        var temp = Source()
        
        temp.isActive = false  // this is set later by single patch parsing
        
        var offset: Int = 0
        var b: Byte = 0
        var index: Int = 0
        
        // s30/s31/s32/s33
        b = data.next(&offset)
        temp.delay = Int(b & 0x7f)

        // s34/s35/s36/s37
        b = data.next(&offset)
        
        // This byte has the wave select high bit in b0,
        // and KS curve = bits 4...6
        index = Int(b.bitField(start: 4, end: 7))
        temp.keyScalingCurve = KeyScalingCurve.allCases[index]
        //print("KS curve = \(keyScalingCurve)")

        // This byte has the wave select low value 0~127 in bits 0...6
        let b2 = data.next(&offset)
        
        temp.wave = Wave(highByte: b, lowByte: b2)

        b = data.next(&offset)
        
        // Here the MIDI implementation's SysEx format is a little unclear.
        // My interpretation is that the low six bits are the coarse value,
        // and b6 is the key tracking bit (b7 is zero).
        
        temp.keyTrack = b.isBitSet(6)
        temp.coarse = Int((b & 0x3f)) - 24  // 00 ~ 48 to ±24
        
        b = data.next(&offset)
        let key = b & 0x7f
        temp.fixedKey = FixedKey(key: key)

        b = data.next(&offset)
        temp.fine = Int((b & 0x7f)) - 50

        b = data.next(&offset)
        temp.pressureFrequency = b.isBitSet(0)
        temp.vibrato = b.isBitSet(1)
        index = Int((b >> 2) & 0b111)
        temp.velocityCurve = VelocityCurve.allCases[index]

        return .success(temp)
    }
    
    /// Gets the System Exclusive data for this source.
    public var data: ByteArray {
        var buf = ByteArray()
        
        // isActive is not emitted, that information is in the single
                    
        buf.append(Byte(delay))
        
        // s34/s35/s36/s37 wave select h and ks
        let ksCurve = keyScalingCurve.rawValue - 1  // bring KS curve to range 0~7
        var s34 = Byte(ksCurve) << 4  // shift it to the top four bits

        let ws = wave.select
        if ws.high == .one {
            s34.setBit(0)
        }
        buf.append(s34)
        
        // s38/s39/s40/s41 wave select l
        let s38 = Byte.fromBits(bits: ws.low)
        buf.append(s38)
    
        // s42/s43/s44/s45 key track and coarse
        var s42 = Byte(coarse + 24)  // bring into 0~48
        if keyTrack {
            s42.setBit(6)
        }
        buf.append(s42)
        
        // s46/s47/s48/s49
        buf.append(fixedKey.key)
        
        // s50/s51/s52/s53
        buf.append(Byte(fine + 50))  // bring into 0~100
        
        // s54/s55/s56/s57 vel curve, vib/a.bend, prs/freq
        var s54 = Byte(velocityCurve.rawValue - 1) << 2
        if vibrato {
            s54.setBit(1)
        }
        if pressureFrequency {
            s54.setBit(0)
        }
        buf.append(s54)
        
        return buf
    }
}

// MARK: - CustomStringConvertible

extension Source: CustomStringConvertible {
    /// Gets a printable string representation of the source.
    public var description: String {
        var lines = [String]()
        lines.append("Delay = \(delay)")
        lines.append("Wave = \(wave)")
        lines.append("Key track = \(keyTrack)")
        lines.append("Coarse = \(coarse), Fine = \(fine)")
        lines.append("Fixed key = \(fixedKey)")
        lines.append("Press. freq = \(pressureFrequency), Vibrato = \(vibrato)")
        lines.append("Velocity curve = \(velocityCurve)")
        lines.append("Key scaling curve = \(keyScalingCurve)")
        return lines.joined(separator: "\n")
    }
}
