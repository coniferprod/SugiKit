import Foundation

import SyxPack


/// Represents a single patch.
public class SinglePatch: HashableClass, Identifiable {
    /// The data size of a single patch.
    public static let dataSize = 131
    
    /// The number of sources in a single patch.
    public static let sourceCount = 4
    
    public var name: PatchName  // name (10 characters)
    public var volume: Level  // volume 0~100
    public var effect: EffectNumber  // effect patch number 1~32 (in SysEx 0~31)
    public var submix: Submix // A...H
        
    public var sourceMode: SourceMode
    public var polyphonyMode: PolyphonyMode
    public var am12: Bool
    public var am34: Bool
        
    public var benderRange: BenderRange  // 0~12 in semitones
    public var pressFreq: Depth // -50~+50 (0~100 in SysEx)
    public var wheelAssign: WheelAssign
    public var wheelDepth: Depth  // -50 ... +50
    public var autoBend: AutoBend
    public var vibrato: Vibrato
    public var lfo: LFO
    public var sources: [Source]
    public var amplifiers: [Amplifier]
    public var filter1: Filter
    public var filter2: Filter

    /// Initializes a single patch with default settings.
    public override init() {
        name = PatchName("NewSingle")
        volume = Level(90)
        effect = EffectNumber(1)
        submix = .a
        
        sourceMode = .normal
        polyphonyMode = .poly1
        am12 = false
        am34 = false
                
        benderRange = BenderRange(0)
        pressFreq = Depth(0)
        wheelAssign = .cutoff
        wheelDepth = Depth(0)
        autoBend = AutoBend()
        vibrato = Vibrato()
        lfo = LFO()
        sources = [Source(), Source(), Source(), Source()]
        amplifiers = [Amplifier(), Amplifier(), Amplifier(), Amplifier()]
        filter1 = Filter()
        filter2 = Filter()
    }
    
    /// Parse single patch data from MIDI System Exclusive data bytes.
    /// - Parameter data: The data bytes.
    /// - Returns: A result type with valid `SinglePatch` data, or an instance of `ParseError`.
    public static func parse(from data: ByteArray) -> Result<SinglePatch, ParseError> {
        guard data.count >= SinglePatch.dataSize else {
            return .failure(.notEnoughData(data.count, SinglePatch.dataSize))
        }
        
        var offset = 0
        var b: Byte = 0
        var index = 0  // reused for enumerated types

        let temp = SinglePatch()  // initialize with defaults and then fill in
        
        let nameData = data.slice(from: offset, length: PatchName.length)
        switch PatchName.parse(from: nameData) {
        case .success(let name):
            temp.name = name
        case .failure(_):
            return .failure(.invalidData(offset))
        }
        offset += PatchName.length

        b = data.next(&offset)
        temp.volume = Level(Int(b))

        // effect = s11 bits 0...4
        b = data.next(&offset)
        temp.effect = EffectNumber(Int(b & 0b00011111) + 1)  // mask out top three bits just in case, then bring into range 1~32

        // output select = s12 bits 0...2
        b = data.next(&offset)
        index = Int(b & 0b00000111) // should now have a value 0~7
        if let sm = Submix(index: index) {
            temp.submix = sm
        }
        else {
            return .failure(.invalidData(offset))
        }

        // source mode = s13 bits 0...1
        b = data.next(&offset)
        
        index = Int(b.bitField(start: 0, end: 2))
        if let smode = SourceMode(index: index) {
            temp.sourceMode = smode
        }
        else {
            return .failure(.invalidData(offset))
        }

        index = Int(b.bitField(start: 2, end: 4))
        if let pmode = PolyphonyMode(index: index) {
            temp.polyphonyMode = pmode
        }
        else {
            return .failure(.invalidData(offset))
        }
        
        temp.am12 = b.isBitSet(4)
        temp.am34 = b.isBitSet(5)

        b = data.next(&offset)
        let activeSourcesByte = b  // save this byte for later
        // The active status of the sources is set later when they have been
        // parsed and initialized.
        
        // Collect the bytes that make up the vibrato settings.
        // First byte comes from bits 4...5 of s14.
        var vibratoBytes = ByteArray()
        vibratoBytes.append(b.bitField(start: 4, end: 6))

        b = data.next(&offset)  // s15
        // Pitch bend = s15 bits 0...3
        temp.benderRange = BenderRange(Int(b.bitField(start: 0, end: 4)))
        
        // Wheel assign = s15 bits 4...5
        index = Int(b.bitField(start: 4, end: 6))
        if let wa = WheelAssign(index: index) {
            temp.wheelAssign = wa
        }
        else {
            return .failure(.invalidData(offset))
        }

        b = data.next(&offset)  // s16
        vibratoBytes.append(b)

        b = data.next(&offset)  // s17
        // Wheel depth = s17 bits 0...6
        temp.wheelDepth = Depth(Int((b & 0x7f)) - 50)  // 0~100 to ±50
        
        // s18 ... s21
        let autoBendBytes = data.slice(from: offset, length: AutoBend.dataSize)
        switch AutoBend.parse(from: autoBendBytes) {
        case .success(let autoBend):
            temp.autoBend = autoBend
        case .failure(let error):
            return .failure(error)
        }
        offset += AutoBend.dataSize
        
        b = data.next(&offset)  // s22
        vibratoBytes.append(b)

        b = data.next(&offset)  // s23
        vibratoBytes.append(b)
     
        // Finally we have all the vibrato bytes
        switch Vibrato.parse(from: vibratoBytes) {
        case .success(let vibrato):
            temp.vibrato = vibrato
        case .failure(let error):
            return .failure(error)
        }
        // Don't adjust the offset! The vibrato bytes have been collected earlier.

        let lfoBytes = data.slice(from: offset, length: LFO.dataSize)
        switch LFO.parse(from: lfoBytes) {
        case .success(let lfo):
            temp.lfo = lfo
        case .failure(let error):
            return .failure(error)
        }
        offset += LFO.dataSize

        b = data.next(&offset)
        temp.pressFreq = Depth(Int((b & 0x7f)) - 50) // 0~100 to ±50
        
        let sourceByteCount = SinglePatch.sourceCount * Source.dataSize
        let sourceBytes = data.slice(from: offset, length: sourceByteCount)
        for i in 0..<SinglePatch.sourceCount {
            let sourceData = sourceBytes.everyNthByte(n: 4, start: i)
            switch Source.parse(from: sourceData) {
            case .success(let source):
                temp.sources.append(source)
            case .failure(let error):
                return .failure(error)
            }
        }
        offset += sourceByteCount
        
        // Now it's time to set the active status of the sources
        for i in 0..<SinglePatch.sourceCount {
            // The description in the SysEx spec seems to be backwards:
            // actually 0 is mute OFF and 1 is mute ON.
            temp.sources[i].isActive = !activeSourcesByte.isBitSet(i)
        }
        
        let amplifierByteCount = Amplifier.dataSize * SinglePatch.sourceCount
        let amplifierBytes = data.slice(from: offset, length: amplifierByteCount)
        
        for i in 0..<SinglePatch.sourceCount {
            let amplifierData = amplifierBytes.everyNthByte(n: 4, start: i)
            switch Amplifier.parse(from: amplifierData) {
            case .success(let amplifier):
                temp.amplifiers.append(amplifier)
            case .failure(let error):
                return .failure(error)
            }
        }
        offset += amplifierByteCount

        let filterByteCount = Filter.dataSize * 2
        let filterBytes = data.slice(from: offset, length: filterByteCount)
        
        for i in 0..<2 {
            let filterData = filterBytes.everyNthByte(n: 2, start: i)
            switch Filter.parse(from: filterData) {
            case .success(let filter):
                if i == 0 {
                    temp.filter1 = filter
                }
                else {
                    temp.filter2 = filter
                }
            case .failure(let error):
                return .failure(error)
            }
        }
        offset += filterByteCount
        
        return .success(temp)
    }
    
    // Gets the System Exclusive data for this single patch.
    private var data: ByteArray {
        var d = ByteArray()

        d.append(contentsOf: self.name.asData())
        d.append(Byte(volume.value)) // s10
        d.append(Byte(effect.value - 1)) // s11: 1~32 to 0~31
        
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
        
        d.append((Byte(wheelAssign.index) << 4) | Byte(benderRange.value))  // s15
        d.append(Byte(vibrato.speed.value)) // s16
        d.append(Byte(wheelDepth.value + 50))  // s17
        d.append(contentsOf: autoBend.asData())  // s18 ... s21
        d.append(Byte(vibrato.pressureDepth.value + 50))  // s22
        d.append(Byte(vibrato.depth.value + 50))  // s23
        d.append(contentsOf: lfo.asData())  // s24 ... s28
        d.append(Byte(pressFreq.value + 50))  // s29

        // The source data are interleaved, with one byte from each first,
        // then the second, etc. That's why they are emitted in this slightly
        // inelegant way. The same applies for DCA and DCF data.

        let s1data = sources[0].asData()
        let s2data = sources[1].asData()
        let s3data = sources[2].asData()
        let s4data = sources[3].asData()
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
        
        let f1Data = filter1.asData()
        let f2Data = filter2.asData()
        for i in 0 ..< f1Data.count {
            d.append(f1Data[i])
            d.append(f2Data[i])
        }

        return d
    }
}

// MARK: - SystemExclusiveData

extension SinglePatch: SystemExclusiveData {
    /// Gets the System Exclusive data for this single patch with checksum.
    public func asData() -> ByteArray {
        var buf = ByteArray()
        
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        
        return buf
    }
    
    /// Gets the length of the data.
    public var dataLength: Int { SinglePatch.dataSize }
}

// MARK: - CustomStringConvertible

extension SinglePatch: CustomStringConvertible {
    /// Gets a printable string representation of the single patch.
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
