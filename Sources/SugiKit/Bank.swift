import Foundation

public struct Bank: Codable {
    static let singlePatchCount = 64
    static let multiPatchCount = 64
    static let effectPatchCount = 32
    
    public var singles: [SinglePatch]
    public var multis: [MultiPatch]
    public var drum: Drum
    public var effects: [EffectPatch]
    
    public init() {
        singles = Array(repeating: SinglePatch(), count: Bank.singlePatchCount)
        multis = Array(repeating: MultiPatch(), count: Bank.multiPatchCount)
        drum = Drum()
        effects = Array(repeating: EffectPatch(), count: Bank.effectPatchCount)
    }
    
    public init(bytes buffer: ByteArray) {
        singles = Array(repeating: SinglePatch(), count: Bank.singlePatchCount)
        multis = Array(repeating: MultiPatch(), count: Bank.multiPatchCount)
        drum = Drum()
        effects = Array(repeating: EffectPatch(), count: Bank.effectPatchCount)

        guard buffer.count == allPatchDataLength else {
            print("Buffer is the wrong size, initialized bank with defaults")
            return
        }

        var offset = 0
        var data = ByteArray(buffer)
        data.removeFirst(SystemExclusiveHeader.dataSize)  // eat the header
        offset += SystemExclusiveHeader.dataSize  // but maintain an offset so we know where we are
        
        for i in 0 ..< Bank.singlePatchCount {
            let singleData = ByteArray(data[..<SinglePatch.dataSize])
            singles[i] = SinglePatch(bytes: singleData)
            data.removeFirst(SinglePatch.dataSize)
            offset += SinglePatch.dataSize
        }
        
        for i in 0 ..< Bank.multiPatchCount {
            let multiData = ByteArray(data[..<MultiPatch.dataSize])
            multis[i] = MultiPatch(bytes: multiData)
            data.removeFirst(MultiPatch.dataSize)
            offset += MultiPatch.dataSize
        }

        drum = Drum(bytes: ByteArray(data[..<Drum.dataSize]))
        data.removeFirst(Drum.dataSize)
        offset += Drum.dataSize
        
        for i in 0 ..< Bank.effectPatchCount {
            let effectData = ByteArray(data[..<EffectPatch.dataSize])
            effects[i] = EffectPatch(bytes: effectData)
            data.removeFirst(EffectPatch.dataSize)
            offset += EffectPatch.dataSize
        }
    }
    
    public init(_ data: Data) {
        singles = Array(repeating: SinglePatch(), count: Bank.singlePatchCount)
        multis = Array(repeating: MultiPatch(), count: Bank.multiPatchCount)
        drum = Drum()
        effects = Array(repeating: EffectPatch(), count: Bank.effectPatchCount)
        
        var offset = SystemExclusiveHeader.dataSize
        
        for i in 0 ..< Bank.singlePatchCount {
            let singleData = data.subdata(in: offset ..< offset + SinglePatch.dataSize)
            singles[i] = SinglePatch(singleData)
            offset += SinglePatch.dataSize
        }

        for i in 0 ..< Bank.multiPatchCount {
            let multiData = data.subdata(in: offset ..< offset + MultiPatch.dataSize)
            multis[i] = MultiPatch(multiData)
            offset += MultiPatch.dataSize
        }
        
        drum = Drum(bytes: ByteArray(data.subdata(in: offset ..< offset + Drum.dataSize)))
        offset += Drum.dataSize
        
        for i in 0 ..< Bank.effectPatchCount {
            let effectData = data.subdata(in: offset ..< offset + EffectPatch.dataSize)
            effects[i] = EffectPatch(bytes: ByteArray(effectData))
            offset += EffectPatch.dataSize
        }
        
    }
    
    /// Returns the System Exclusive data for the bank. Each section has its own checksum.
    public var systemExclusiveData: ByteArray {
        var buffer = ByteArray()

        singles.forEach { buffer.append(contentsOf: $0.systemExclusiveData) }
        multis.forEach { buffer.append(contentsOf: $0.systemExclusiveData) }
        buffer.append(contentsOf: drum.systemExclusiveData)
        effects.forEach { buffer.append(contentsOf: $0.systemExclusiveData) }

        return buffer
    }
    
    /*
    public var systemExclusiveData: Data {
        var d = Data()
        
        singles.forEach { d.append($0.systemExclusiveData) }
        multis.forEach { d.append($0.systemExclusiveData) }
        d.append(drum.systemExclusiveData)
        effects.forEach { d.append($0.systemExclusiveData) }
        
        return d
    }
    */
    
    public static func nameForPatch(_ n: Int) -> String {
        let patchesPerBank = 16
        let bankIndex = n / patchesPerBank
        let bankLetters = ["A", "B", "C", "D"]
        let letter = bankLetters[bankIndex]
        let patchIndex = (n % patchesPerBank) + 1

        return "\(letter)-\(patchIndex)"
    }
}
