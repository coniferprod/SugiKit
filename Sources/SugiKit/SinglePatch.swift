import Foundation

/// Represents a single patch.
public class SinglePatch: HashableClass, Codable, Identifiable, CustomStringConvertible {
    static let dataSize = 131
    static let sourceCount = 4
    static let nameLength = 10

    public var name: String  // name (10 characters)
    public var volume: Int  // volume 0~100
    public var effect: Int  // effect patch number 1~32 (in SysEx 0~31)
    public var submix: SubmixType // A...H
        
    public var sourceMode: SourceModeType
    public var polyphonyMode: PolyphonyModeType
    public var am12: Bool
    public var am34: Bool
        
    public var activeSources: [Bool]  // true if source is active, false if not
    public var benderRange: Int  // 0~12 in semitones
    public var pressFreq: Int // 0~100 (±50)
    public var wheelAssign: WheelAssignType
    public var wheelDepth: Int  // -50 ... +50
    public var autoBend: AutoBendSettings  // this is portamento
    public var vibrato: VibratoSettings
    public var lfo: LFOSettings
    public var sources: [Source]
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
        autoBend = AutoBendSettings()
        vibrato = VibratoSettings()
        lfo = LFOSettings()
        sources = [Source(), Source(), Source(), Source()]
        activeSources = [true, true, true, true] // all sources active
        filter1 = Filter()
        filter2 = Filter()
    }
    
    /// Initializes a single patch from system exclusive data.
    public init(bytes buffer: ByteArray) {
        var offset = 0
        var b: Byte = 0
        var index = 0

        let data = ByteArray(buffer)
        self.name = String(bytes: data[..<SinglePatch.nameLength], encoding: .ascii) ?? ""
        offset += SinglePatch.nameLength

        b = buffer[offset]
        offset += 1
        self.volume = Int(b)

        // effect = s11 bits 0...4
        b = buffer[offset]
        offset += 1
        //print("effect byte s11 = 0x\(String(b, radix: 16))")
        let effectPatch = Int(b & 0b00011111) + 1  // mask out top three bits just in case, then bring into range 1~32
        self.effect = effectPatch // use range 1~32 when storing the value, 0~31 in SysEx data
        //print("effect = \(self.effect)")

        // output select = s12 bits 0...2
        b = buffer[offset]
        offset += 1
        let submixIndex = Int(b & 0b00000111) // should now have a value 0~7
        self.submix = SubmixType(index: submixIndex)!
        //print("submix = \(self.submix)")

        // source mode = s13 bits 0...1
        b = buffer[offset]
        offset += 1
        
        index = Int(b.bitField(start: 0, end: 2))
        self.sourceMode = SourceModeType(index: index)!
        //print("source mode = \(self.sourceMode)")
        
        index = Int(b.bitField(start: 2, end: 4))
        self.polyphonyMode = PolyphonyModeType(index: index)!
        //print("polyphony mode = \(self.polyphonyMode)")
        
        self.am12 = b.isBitSet(4)
        //print("AM 1>2 = \(self.am12)")
        self.am34 = b.isBitSet(5)
        //print("AM 3>4 = \(self.am34)")

        b = buffer[offset]
        offset += 1
        self.activeSources = [ // 0/mute, 1/not mute
            !b.isBitSet(0),
            !b.isBitSet(1),
            !b.isBitSet(2),
            !b.isBitSet(3)
        ]
        
        self.vibrato = VibratoSettings()
        index = Int(b.bitField(start: 4, end: 6))
        self.vibrato.shape = LFOShapeType(index: index)!

        b = buffer[offset]
        offset += 1
        // Pitch bend = s15 bits 0...3
            self.benderRange = Int(b.bitField(start: 0, end: 4))
        //print("bender range = \(self.benderRange)")
        
        // Wheel assign = s15 bits 4...5
            index = Int(b.bitField(start: 4, end: 6))
        self.wheelAssign = WheelAssignType(index: index)!
        //print("wheel assign = \(self.wheelAssign)")

        b = buffer[offset]
        offset += 1
        // Vibrato speed = s16 bits 0...6
        self.vibrato.speed = Int(b & 0x7f)

        b = buffer[offset]
        offset += 1
        // Wheel depth = s17 bits 0...6
        self.wheelDepth = Int((b & 0x7f)) - 50  // 0~100 to ±50
        //print("wheel depth = \(self.wheelDepth)")
        
        self.autoBend = AutoBendSettings()
        b = buffer[offset]
        offset += 1
        self.autoBend.time = Int(b & 0x7f)

        b = buffer[offset]
        offset += 1
        self.autoBend.depth = Int((b & 0x7f)) - 50 // 0~100 to ±50

        b = buffer[offset]
        offset += 1
        self.autoBend.keyScalingTime = Int((b & 0x7f)) - 50 // 0~100 to ±50

        b = buffer[offset]
        offset += 1
        self.autoBend.velocityDepth = Int((b & 0x7f)) - 50 // 0~100 to ±50
        
        b = buffer[offset]
        offset += 1
        self.vibrato.pressureDepth = Int((b & 0x7f)) - 50 // 0~100 to ±50

        b = buffer[offset]
        offset += 1
        self.vibrato.depth = Int((b & 0x7f)) - 50 // 0~100 to ±50
     
        self.lfo = LFOSettings()

        b = buffer[offset]
        offset += 1
        index = Int(b & 0x03)
        self.lfo.shape = LFOShapeType(index: index)!

        b = buffer[offset]
        offset += 1
        self.lfo.speed = Int(b & 0x7f)

        b = buffer[offset]
        offset += 1
        self.lfo.delay = Int(b & 0x7f)

        b = buffer[offset]
        offset += 1
        self.lfo.depth = Int((b & 0x7f)) - 50 // 0~100 to ±50

        b = buffer[offset]
        offset += 1
        self.lfo.pressureDepth = Int((b & 0x7f)) - 50 // 0~100 to ±50

        b = buffer[offset]
        offset += 1
        self.pressFreq = Int((b & 0x7f)) - 50 // 0~100 to ±50
        
        let sourceBytes = ByteArray(buffer[offset ..< offset + 28])
        let sourceData: [ByteArray] = [
            everyNthByte(d: sourceBytes, n: 4, start: 0),
            everyNthByte(d: sourceBytes, n: 4, start: 1),
            everyNthByte(d: sourceBytes, n: 4, start: 2),
            everyNthByte(d: sourceBytes, n: 4, start: 3),
        ]

        self.sources = [
            Source(bytes: sourceData[0]),
            Source(bytes: sourceData[1]),
            Source(bytes: sourceData[2]),
            Source(bytes: sourceData[3]),
        ]
        
        offset += 28
        
        let amplifierBytes = ByteArray(buffer[offset ..< offset + 44])
        let amplifierData: [ByteArray] = [
            everyNthByte(d: amplifierBytes, n: 4, start: 0),
            everyNthByte(d: amplifierBytes, n: 4, start: 1),
            everyNthByte(d: amplifierBytes, n: 4, start: 2),
            everyNthByte(d: amplifierBytes, n: 4, start: 3),
        ]
        offset += 44
        
        for (index, data) in amplifierData.enumerated() {
            self.sources[index].amplifier = Amplifier(d: data)
        }
        
        let filterBytes = ByteArray(buffer[offset ..< offset + 28])
        let filterData: [ByteArray] = [
            everyNthByte(d: filterBytes, n: 2, start: 0),
            everyNthByte(d: filterBytes, n: 2, start: 1),
        ]
        offset += 28
        
        self.filter1 = Filter(d: filterData[0])
        self.filter2 = Filter(d: filterData[1])
        
        b = buffer[offset]
        
        // "Check sum value (s130) is the sum of the A5H and s0 ~ s129".
        //print("incoming checksum = \(b)")
        //self.incomingChecksum = b   // store the checksum as we got it from SysEx
    }
        
    public var data: ByteArray {
        var d = ByteArray()
        
        //print("name is \(name.utf8.count) characters")
        for codeUnit in name.utf8 {
            d.append(codeUnit)
        }
        
        // s10
        d.append(Byte(volume))

        // s11
        d.append(Byte(effect - 1)) // 1~32 to 0~31
        
        // s12
        let submixNames = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let submixIndex = submixNames.firstIndex(of: submix.rawValue)
        d.append(Byte(submixIndex!))
        
        // s13
        var s13 = Byte(polyphonyMode.index!) << 2
        s13 |= Byte(sourceMode.index!)
        if am34 {
            s13.setBit(5)
        }
        if am12 {
            s13.setBit(4)
        }
        d.append(s13)
        
        // s14
        var s14: Byte = Byte(vibrato.shape.index!) << 4
        for (i, sm) in activeSources.enumerated() {
            if sm {
                s14.setBit(i)
            }
        }
        d.append(s14)
        
        // s15
        d.append((Byte(wheelAssign.index!) << 4) | Byte(benderRange))
        
        // s16
        d.append(Byte(vibrato.speed))
        
        // s17
        d.append(Byte(wheelDepth + 50))
        
        // s18
        d.append(Byte(autoBend.time))
        
        // s19
        d.append(Byte(autoBend.depth + 50))
        
        // s20
        d.append(Byte(autoBend.keyScalingTime + 50))
        
        // s21
        d.append(Byte(autoBend.velocityDepth + 50))
        
        // s22
        d.append(Byte(vibrato.pressureDepth + 50))

        // s23
        d.append(Byte(vibrato.depth + 50))

        // s24
        d.append(Byte(lfo.shape.index!))

        // s25
        d.append(Byte(lfo.speed))

        // s26
        d.append(Byte(lfo.delay))
        
        // s27
        d.append(Byte(lfo.depth + 50))

        // s28
        d.append(Byte(lfo.pressureDepth + 50))

        // s29
        d.append(Byte(pressFreq + 50))

        // The source data are interleaved, with one byte from each first,
        // then the second, etc. That's why they are emitted in this slightly
        // inelegant way. The same applies for DCA and DCF data.

        let s1data = sources[0].data
        let s2data = sources[1].data
        let s3data = sources[2].data
        let s4data = sources[3].data
        //print("source 1 data length = \(s1data.count)")
        for i in 0 ..< s1data.count {
            d.append(s1data[i])
            d.append(s2data[i])
            d.append(s3data[i])
            d.append(s4data[i])
        }

        let amp1Data = sources[0].amplifier.data
        let amp2Data = sources[1].amplifier.data
        let amp3Data = sources[2].amplifier.data
        let amp4Data = sources[3].amplifier.data
        //print("amp 1 data length = \(amp1Data.count)")
        for i in 0 ..< Amplifier.dataSize {
            d.append(amp1Data[i])
            d.append(amp2Data[i])
            d.append(amp3Data[i])
            d.append(amp4Data[i])
        }
        
        let f1Data = filter1.data
        let f2Data = filter2.data
        //print("filter 1 data length = \(f1Data.count)")
        for i in 0 ..< f1Data.count {
            d.append(f1Data[i])
            d.append(f2Data[i])
        }

        return d
    }
    
    /// Gets the data and the checksum calculated based on the data.
    public var systemExclusiveData: ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return d
    }
    
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
        for (index, element) in activeSources.enumerated() {
            muteString += element ? String(index + 1) : "-"
        }
        lines.append("Sources = \(muteString)")
        
        lines.append("Bender range = \(benderRange) semitones")
        lines.append("Pressure frequency = \(pressFreq)")
        lines.append("Wheel assign = \(wheelAssign)")
        lines.append("Wheel depth = \(wheelDepth)")

        lines.append("\(autoBend)")
        
        for (index, source) in sources.enumerated() {
            if !activeSources[index] {  // this source is muted
                continue
            }
            
            lines.append(source.description)
        }
        
        return lines.joined(separator: "\n")
    }
}
