import Foundation

/// Represents a full bank with 64 singles, 64 multis, drum, and 32 effects.
public struct Bank: Codable {
    public static let singlePatchCount = 64
    public static let multiPatchCount = 64
    public static let effectPatchCount = 32
    
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
        singles = [SinglePatch]()
        multis = [MultiPatch]()
        effects = [EffectPatch]()

        var offset = 0
        var data = ByteArray(buffer)
        data.removeFirst(SystemExclusiveHeader.dataSize)  // eat the header
        offset += SystemExclusiveHeader.dataSize  // but maintain an offset so we know where we are
        
        for _ in 0 ..< Bank.singlePatchCount {
            let singleData = ByteArray(data[..<SinglePatch.dataSize])
            singles.append(SinglePatch(bytes: singleData))
            data.removeFirst(SinglePatch.dataSize)
            offset += SinglePatch.dataSize
        }
        
        for _ in 0 ..< Bank.multiPatchCount {
            let multiData = ByteArray(data[..<MultiPatch.dataSize])
            multis.append(MultiPatch(bytes: multiData))
            data.removeFirst(MultiPatch.dataSize)
            offset += MultiPatch.dataSize
        }

        let drumBytes = ByteArray(data[..<Drum.dataSize])
        //print("drum:\n\(drumBytes.hexDump)")
        drum = Drum(bytes: drumBytes)
        data.removeFirst(Drum.dataSize)
        offset += Drum.dataSize
        
        for _ in 0 ..< Bank.effectPatchCount {
            let effectData = ByteArray(data[..<EffectPatch.dataSize])
            effects.append(EffectPatch(bytes: effectData))
            data.removeFirst(EffectPatch.dataSize)
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
    
    public static func nameForPatch(_ n: Int) -> String {
        let patchesPerBank = 16
        let bankIndex = n / patchesPerBank
        let bankLetters = ["A", "B", "C", "D"]
        let letter = bankLetters[bankIndex]
        let patchIndex = (n % patchesPerBank) + 1

        return "\(letter)-\(patchIndex)"
    }
}
