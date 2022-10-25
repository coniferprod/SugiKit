import Foundation

import SyxPack


/// Represents a full bank with 64 singles, 64 multis, drum, and 32 effects.
public struct Bank: Codable, Equatable {
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
    
    /// Initializes the bank from System Exclusive data.
    /// The byte buffer passed in must not contain the SysEx header
    public init(bytes buffer: ByteArray) {
        singles = [SinglePatch]()
        multis = [MultiPatch]()
        effects = [EffectPatch]()

        var offset = 0
        //offset += SystemExclusiveHeader.dataSize  // skip the SysEx header
        
        for _ in 0 ..< Bank.singlePatchCount {
            let singleData = buffer.slice(from: offset, length: SinglePatch.dataSize)
            singles.append(SinglePatch(bytes: singleData))
            offset += SinglePatch.dataSize
        }
        
        for _ in 0 ..< Bank.multiPatchCount {
            let multiData = buffer.slice(from: offset, length: MultiPatch.dataSize)
            multis.append(MultiPatch(bytes: multiData))
            offset += MultiPatch.dataSize
        }

        let drumBytes = buffer.slice(from: offset, length: Drum.dataSize)
        //print("drum:\n\(drumBytes.hexDump)")
        drum = Drum(bytes: drumBytes)
        offset += Drum.dataSize
        
        for _ in 0 ..< Bank.effectPatchCount {
            let effectData = buffer.slice(from: offset, length: EffectPatch.dataSize)
            effects.append(EffectPatch(bytes: effectData))
            offset += EffectPatch.dataSize
        }
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

// MARK: - SystemExclusiveData

extension Bank: SystemExclusiveData {
    /// Gets the System Exclusive data for the bank. Each section has its own checksum.
    public func asData() -> ByteArray {
        var buffer = ByteArray()

        singles.forEach { buffer.append(contentsOf: $0.asData()) }
        multis.forEach { buffer.append(contentsOf: $0.asData()) }
        buffer.append(contentsOf: drum.asData())
        effects.forEach { buffer.append(contentsOf: $0.asData()) }

        return buffer
    }
}
