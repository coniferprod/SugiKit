import Foundation

import SyxPack


/// Represents a single patch.
public class SinglePatch: HashableClass, Codable, Identifiable {
    static let dataSize = 131
    static let sourceCount = 4
    static let nameLength = 10

    @PatchName public var name: String  // name (10 characters)
    public var volume: UInt  // volume 0~100
    public var effect: UInt  // effect patch number 1~32 (in SysEx 0~31)
    public var submix: Submix // A...H
        
    public var sourceMode: SourceMode
    public var polyphonyMode: PolyphonyMode
    public var am12: Bool
    public var am34: Bool
        
    public var benderRange: UInt  // 0~12 in semitones
    public var pressFreq: Int // -50~+50 (0~100 in SysEx)
    public var wheelAssign: WheelAssign
    public var wheelDepth: Int  // -50 ... +50
    public var autoBend: AutoBend
    public var vibrato: Vibrato
    public var lfo: LFO
    public var sources: [Source]
    public var amplifiers: [Amplifier]
    public var filter1: Filter
    public var filter2: Filter

    public override init() {
        name = "Single    "
        volume = 90
        effect = 1
        submix = .a
        
        sourceMode = .normal
        polyphonyMode = .poly1
        am12 = false
        am34 = false
                
        benderRange = 0
        pressFreq = 0
        wheelAssign = .cutoff
        wheelDepth = 0
        autoBend = AutoBend()
        vibrato = Vibrato()
        lfo = LFO()
        sources = [Source(), Source(), Source(), Source()]
        amplifiers = [Amplifier(), Amplifier(), Amplifier(), Amplifier()]
        filter1 = Filter()
        filter2 = Filter()
    }
    
    /// Initializes a single patch from system exclusive data.
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0
        var index = 0  // reused for enumerated types

        // Get the patch name from 10 bytes representing ASCII characters.
        // If that fails, use a string with 10 spaces. Also, replace any NULs with spaces.
        let originalName = String(bytes: buffer.slice(from: offset, length: PatchName.length), encoding: .ascii) ?? String(repeating: " ", count: PatchName.length)
        name = originalName.replacingOccurrences(of: "\0", with: " ")
        offset += PatchName.length

        b = buffer.next(&offset)
        volume = UInt(b)

        // effect = s11 bits 0...4
        b = buffer.next(&offset)
        //print("effect byte s11 = 0x\(String(b, radix: 16))")
        effect = UInt(Int(b & 0b00011111) + 1)  // mask out top three bits just in case, then bring into range 1~32

        // output select = s12 bits 0...2
        b = buffer.next(&offset)
        index = Int(b & 0b00000111) // should now have a value 0~7
        if let sm = Submix(index: index) {
            submix = sm
        }
        else {
            submix = .a
            print("\(#function): Value out of range for submix: \(index). Using default value ('\(submix)').", to: &standardError)
        }

        // source mode = s13 bits 0...1
        b = buffer.next(&offset)
        
        index = Int(b.bitField(start: 0, end: 2))
        if let smode = SourceMode(index: index) {
            sourceMode = smode
        }
        else {
            sourceMode = .normal
            print("\(#file):\(#line): \(#function): Value out of range for source mode: \(index). Using default value ('\(sourceMode)').", to: &standardError)
        }

        index = Int(b.bitField(start: 2, end: 4))
        if let pmode = PolyphonyMode(index: index) {
            polyphonyMode = pmode
        }
        else {
            polyphonyMode = .poly1
            print("Value out of range for polyphony mode: \(index). Using default value ('\(polyphonyMode)').", to: &standardError)
        }
        
        am12 = b.isBitSet(4)
        //print("AM 1>2 = \(self.am12)")
        am34 = b.isBitSet(5)
        //print("AM 3>4 = \(self.am34)")

        b = buffer.next(&offset)
        let activeSourcesByte = b  // save this byte for later
        // The active status of the sources is set later when they have been
        // parsed and initialized.
        
        // Collect the bytes that make up the vibrato settings.
        // First byte comes from bits 4...5 of s14.
        var vibratoBytes = ByteArray()
        vibratoBytes.append(b.bitField(start: 4, end: 6))

        b = buffer.next(&offset)  // s15
        // Pitch bend = s15 bits 0...3
        benderRange = UInt(b.bitField(start: 0, end: 4))
        //print("bender range = \(benderRange)", to: &standardError)
        
        // Wheel assign = s15 bits 4...5
        index = Int(b.bitField(start: 4, end: 6))
        if let wa = WheelAssign(index: index) {
            wheelAssign = wa
        }
        else {
            wheelAssign = .cutoff
            print("Value out of range for wheel assign: \(index). Using default value ('\(wheelAssign)').", to: &standardError)
        }

        b = buffer.next(&offset)  // s16
        vibratoBytes.append(b)

        b = buffer.next(&offset)  // s17
        // Wheel depth = s17 bits 0...6
        wheelDepth = Int((b & 0x7f)) - 50  // 0~100 to ±50
        //print("wheel depth = \(self.wheelDepth)")
        
        // s18 ... s21
        autoBend = AutoBend(bytes: buffer.slice(from: offset, length: AutoBend.dataSize))
        offset += AutoBend.dataSize
        
        b = buffer.next(&offset)  // s22
        vibratoBytes.append(b)

        b = buffer.next(&offset)  // s23
        vibratoBytes.append(b)
     
        // Finally we have all the vibrato bytes
        vibrato = Vibrato(bytes: vibratoBytes)
        
        lfo = LFO(bytes: buffer.slice(from: offset, length: LFO.dataSize))
        offset += LFO.dataSize

        b = buffer.next(&offset)
        self.pressFreq = Int((b & 0x7f)) - 50 // 0~100 to ±50
        
        let sourceByteCount = 28
        let sourceBytes = buffer.slice(from: offset, length: sourceByteCount)
        let sourceData: [ByteArray] = [
            sourceBytes.everyNthByte(n: 4, start: 0),
            sourceBytes.everyNthByte(n: 4, start: 1),
            sourceBytes.everyNthByte(n: 4, start: 2),
            sourceBytes.everyNthByte(n: 4, start: 3),
        ]
        self.sources = [
            Source(bytes: sourceData[0]),
            Source(bytes: sourceData[1]),
            Source(bytes: sourceData[2]),
            Source(bytes: sourceData[3]),
        ]
        offset += sourceByteCount

        // Now it's time to set the active status of the sources
        for i in 0..<SinglePatch.sourceCount {
            // The description in the SysEx spec seems to be backwards:
            // actually 0 is mute OFF and 1 is mute ON.
            if activeSourcesByte.isBitSet(i) {
                self.sources[i].isActive = false
            }
            else {
                self.sources[i].isActive = true
            }
        }
        
        let amplifierByteCount = 44
        let amplifierBytes = buffer.slice(from: offset, length: amplifierByteCount)
        let amplifierData: [ByteArray] = [
            amplifierBytes.everyNthByte(n: 4, start: 0),
            amplifierBytes.everyNthByte(n: 4, start: 1),
            amplifierBytes.everyNthByte(n: 4, start: 2),
            amplifierBytes.everyNthByte(n: 4, start: 3),
        ]
        self.amplifiers = [
            Amplifier(bytes: amplifierData[0]),
            Amplifier(bytes: amplifierData[1]),
            Amplifier(bytes: amplifierData[2]),
            Amplifier(bytes: amplifierData[3]),
        ]
        offset += amplifierByteCount

        let filterByteCount = 28
        let filterBytes = buffer.slice(from: offset, length: filterByteCount)
        let filterData: [ByteArray] = [
            filterBytes.everyNthByte(n: 2, start: 0),
            filterBytes.everyNthByte(n: 2, start: 1),
        ]
        offset += filterByteCount
        
        self.filter1 = Filter(d: filterData[0])
        self.filter2 = Filter(d: filterData[1])
        
        //b = buffer.next(&offset)

        // "Check sum value (s130) is the sum of the A5H and s0 ~ s129".
        //print("incoming checksum = \(b)")
        //self.incomingChecksum = b   // store the checksum as we got it from SysEx
    }
        
    public var data: ByteArray {
        var d = ByteArray()

        d.append(contentsOf: _name.asData())
        d.append(Byte(volume)) // s10
        d.append(Byte(effect - 1)) // s11: 1~32 to 0~31
        
        let submixNames = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let submixIndex = submixNames.firstIndex(of: submix.rawValue)
        d.append(Byte(submixIndex!))  // s12
        
        var s13 = Byte(polyphonyMode.index) << 2
        s13 |= Byte(sourceMode.index)
        if am34 {
            s13.setBit(5)
        }
        if am12 {
            s13.setBit(4)
        }
        d.append(s13)
        
        var s14: Byte = Byte(vibrato.shape.index) << 4
        for i in 0..<SinglePatch.sourceCount {
            if self.sources[i].isActive {
                s14.setBit(i)
            }
            else {
                s14.clearBit(i)
            }
        }
        d.append(s14)
        
        d.append((Byte(wheelAssign.index) << 4) | Byte(benderRange))  // s15
        d.append(Byte(vibrato.speed)) // s16
        d.append(Byte(wheelDepth + 50))  // s17
        d.append(contentsOf: autoBend.data)  // s18 ... s21
        d.append(Byte(vibrato.pressureDepth + 50))  // s22
        d.append(Byte(vibrato.depth + 50))  // s23
        d.append(contentsOf: lfo.data)  // s24 ... s28
        d.append(Byte(pressFreq + 50))  // s29

        // The source data are interleaved, with one byte from each first,
        // then the second, etc. That's why they are emitted in this slightly
        // inelegant way. The same applies for DCA and DCF data.

        let s1data = sources[0].data
        let s2data = sources[1].data
        let s3data = sources[2].data
        let s4data = sources[3].data
        for i in 0 ..< s1data.count {
            d.append(s1data[i])
            d.append(s2data[i])
            d.append(s3data[i])
            d.append(s4data[i])
        }

        let amp1Data = amplifiers[0].asData()
        let amp2Data = amplifiers[1].asData()
        let amp3Data = amplifiers[2].asData()
        let amp4Data = amplifiers[3].asData()
        for i in 0 ..< Amplifier.dataSize {
            d.append(amp1Data[i])
            d.append(amp2Data[i])
            d.append(amp3Data[i])
            d.append(amp4Data[i])
        }
        
        let f1Data = filter1.data
        let f2Data = filter2.data
        for i in 0 ..< f1Data.count {
            d.append(f1Data[i])
            d.append(f2Data[i])
        }

        return d
    }
}

// MARK: - SystemExclusiveData

extension SinglePatch: SystemExclusiveData {
    public func asData() -> ByteArray {
        var buf = ByteArray()
        
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        
        return buf
    }
}

// MARK: - CustomStringConvertible

extension SinglePatch: CustomStringConvertible {
    public var description: String {
        var lines = [String]()
        lines.append("Name = \(name)")
        lines.append("Volume = \(volume)")
        lines.append("Effect patch = \(effect)")
        lines.append("Submix ch = \(submix)")
        lines.append("Source mode = \(sourceMode)")
        lines.append("Polyphony mode = \(polyphonyMode)")
        lines.append("AM1>2 = \(am12)")
        lines.append("AM3>4 = \(am34)")
        
        var muteString = ""
        for i in 0..<SinglePatch.sourceCount {
            muteString += self.sources[i].isActive ? String(i + 1) : "-"
        }
        lines.append("Sources = \(muteString)")
        
        lines.append("Bender range = \(benderRange) semitones")
        lines.append("Pressure frequency = \(pressFreq)")
        lines.append("Wheel assign = \(wheelAssign)")
        lines.append("Wheel depth = \(wheelDepth)")

        lines.append("\(autoBend)")
        
        for (index, source) in self.sources.enumerated() {
            if source.isActive {
                lines.append("SOURCE \(index + 1):")
                lines.append(source.description)
            }
        }
        
        for (_, amplifier) in amplifiers.enumerated() {
            lines.append(amplifier.description)
        }
        
        lines.append("F1: \(filter1.description)")
        lines.append("F2: \(filter2.description)")
        
        return lines.joined(separator: "\n")
    }
}
