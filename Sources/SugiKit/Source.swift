import Foundation

/// Represents one source in a single patch.
public struct Source: Codable {
    static let dataSize = 18

    public var delay: Int // 0~100
    public var velocityCurve: VelocityCurveType
    public var keyScalingCurve: KeyScalingCurveType
    public var oscillator: Oscillator
    public var amplifier: Amplifier
    
    public init() {
        delay = 0
        velocityCurve = .curve1
        keyScalingCurve = .curve1
        oscillator = Oscillator()
        amplifier = Amplifier()
    }
    
    public init(bytes buffer: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        var index: Int = 0
        
        var d = ByteArray(buffer)
        
        delay = Int(d.first! & 0x7f)
        offset += 1
        d.removeFirst()

        b = d.first!
        offset += 1
        d.removeFirst()

        // KS curve = bits 4...6
        index = Int(b.bitField(start: 4, end: 7))
        keyScalingCurve = KeyScalingCurveType.allCases[index]
        //print("KS curve = \(keyScalingCurve)")
        
        let b2: Byte = d.first!
        offset += 1
        d.removeFirst()
        
        oscillator = Oscillator()
        
        self.oscillator.waveNumber = Source.extractWaveNumber(highByte: b, lowByte: b2)
        //print("wave = \(self.oscillator.waveNumber)")

        b = d.first!
        offset += 1
        d.removeFirst()
        
        // Here the MIDI implementation's SysEx format is a little unclear.
        // My interpretation is that the low six bits are the coarse value,
        // and b6 is the key tracking bit (b7 is zero).
        
        self.oscillator.keyTrack = b.isBitSet(6)
        //print("key track = \(self.oscillator.keyTrack)")
        self.oscillator.coarse = Int((b & 0x3f)) - 24  // 00 ~ 48 to ±24
        //print("coarse = \(self.oscillator.coarse)")
        
        b = d.first!
        offset += 1
        d.removeFirst()
        let key = Int(b & 0x7f)
        // convert key value to key name
        self.oscillator.fixedKey = Source.noteName(for: key)
        //self.oscillator.fixedKey = KeyType(key: Int(b & 0x7f))
        //print("fixed key = \(self.oscillator.fixedKey)")

        b = d.first!
        offset += 1
        d.removeFirst()
        self.oscillator.fine = Int((b & 0x7f)) - 50
        //print("fine = \(self.oscillator.fine)")

        b = d.first!
        offset += 1
        d.removeFirst()
        self.oscillator.pressureFrequency = b.isBitSet(0)
        self.oscillator.vibrato = b.isBitSet(1)
        index = Int((b >> 2) & 0x07)
        velocityCurve = VelocityCurveType.allCases[index]
        
        self.amplifier = Amplifier()  // filled in by single patch parsing
    }
    
    static func extractWaveNumber(highByte: Byte, lowByte: Byte) -> Int {
        //print("highByte = 0x\(String(highByte, radix: 16)), lowByte = 0x\(String(lowByte, radix: 16))")
        let high = Int(highByte & 0x01)
        let low = Int(lowByte & 0x7f)
        //print("high = 0x\(String(high, radix: 16)), low = 0x\(String(low, radix: 16))")
        return ((high << 7) | low) + 1
    }
    
    var data: ByteArray {
        var buf = ByteArray()
                    
        buf.append(Byte(delay))
        
        // s34/s35/s36/s37 wave select h and ks
        let number = self.oscillator.waveNumber - 1  // bring into range 0~255
        let waveNumberString = "\(number, radix: .binary, prefix: false, toWidth: 9)"
        //print("wave number = '\(waveNumberString)' or \(number)")
        let ksCurve = keyScalingCurve.rawValue - 1
        var s34 = Byte(ksCurve) << 4
        if waveNumberString.starts(with: "1") {
            s34.setBit(0)
        }
        buf.append(s34)
        
        // s38/s39/s40/s41 wave select l
        let restIndex = waveNumberString.index(after: waveNumberString.startIndex)
        let s38 = Byte(waveNumberString.suffix(from: restIndex), radix: 2)!
        buf.append(s38)
    
        // s42/s43/s44/s45 key track and coarse
        var s42 = Byte(self.oscillator.coarse + 24)  // bring into 0~48
        if self.oscillator.keyTrack {
            s42.setBit(6)
        }
        buf.append(s42)
        
        // s46/s47/s48/s49
        buf.append(Byte(Source.keyNumber(for: self.oscillator.fixedKey)))
        
        // s50/s51/s52/s53
        buf.append(Byte(self.oscillator.fine + 50))
        
        // s54/s55/s56/s57 vel curve, vib/a.bend, prs/freq
        var s54 = Byte(velocityCurve.rawValue - 1) << 2
        if self.oscillator.vibrato {
            s54.setBit(1)
        }
        if self.oscillator.pressureFrequency {
            s54.setBit(0)
        }
        buf.append(Byte(s54))
        
        return buf
    }
    
    public static func noteName(for key: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = key / 12 - 1
        let name = noteNames[key % 12];
        return "\(name)\(octave)"
    }
    
    public static func keyNumber(for name: String) -> Int {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        var i = 0
        var notePart = ""
        var octavePart = ""
        while i < name.count {
            let c = name[i ..< i + 1]
            if c == "C" || c == "D" || c == "E" || c == "F" || c == "G" || c == "A" || c == "B" {
                notePart += c
            }
            if c == "#" {
                notePart += c
            }
            if c == "-" {
                octavePart += c
            }
            if c == "0" || c == "1" || c == "2" || c == "3" || c == "4" || c == "5" || c == "6" || c == "7" || c == "8" || c == "9" {
                octavePart += c
            }
            i += 1
        }

        if let octave = Int(octavePart), let noteIndex = names.firstIndex(where: { $0 == notePart }) {
            return (octave + 1) * 12 + noteIndex
        }

        return 0
    }
}
