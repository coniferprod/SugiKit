import Foundation

import SyxPack


/// Represents a full bank with 64 singles, 64 multis, drum, and 32 effects.
public struct Bank: Equatable {
    public static let singlePatchCount = 64
    public static let multiPatchCount = 64
    public static let effectPatchCount = 32
    
    public static let dataSize =
        singlePatchCount * SinglePatch.dataSize +
        multiPatchCount * MultiPatch.dataSize +
        effectPatchCount * EffectPatch.dataSize +
        Drum.dataSize
    
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
    
    /// Parse bank data from MIDI System Exclusive data bytes.
    /// - Parameter data: The data bytes.
    /// - Returns: A result type with valid `Bank` data or an instance of `ParseError`.
    public static func parse(from data: ByteArray) -> Result<Bank, ParseError> {
        let totalDataSize =
            Bank.singlePatchCount * SinglePatch.dataSize +
            Bank.multiPatchCount * MultiPatch.dataSize +
            Bank.effectPatchCount * EffectPatch.dataSize +
            Drum.dataSize
        
        guard data.count >= totalDataSize else {
            return .failure(.notEnoughData(data.count, totalDataSize))
        }

        var tempSingles = [SinglePatch]()
        var tempMultis = [MultiPatch]()
        var tempEffects = [EffectPatch]()
        var tempDrum = Drum()

        var offset = 0
        
        for _ in 0 ..< Bank.singlePatchCount {
            let singleData = data.slice(from: offset, length: SinglePatch.dataSize)
            switch SinglePatch.parse(from: singleData) {
            case .success(let patch):
                tempSingles.append(patch)
            case .failure(let error):
                return .failure(error)
            }
            offset += SinglePatch.dataSize
        }
        
        for _ in 0 ..< Bank.multiPatchCount {
            let multiData = data.slice(from: offset, length: MultiPatch.dataSize)
            switch MultiPatch.parse(from: multiData) {
            case .success(let patch):
                tempMultis.append(patch)
            case .failure(let error):
                return .failure(error)
            }
            offset += MultiPatch.dataSize
        }

        let drumBytes = data.slice(from: offset, length: Drum.dataSize)
        //print("drum:\n\(drumBytes.hexDump)")
        switch Drum.parse(from: drumBytes) {
        case .success(let drum):
            tempDrum = drum
        case .failure(let error):
            return .failure(error)
        }
        offset += Drum.dataSize
        
        for _ in 0 ..< Bank.effectPatchCount {
            let effectData = data.slice(from: offset, length: EffectPatch.dataSize)
            switch EffectPatch.parse(from: effectData) {
            case .success(let patch):
                tempEffects.append(patch)
            case .failure(let error):
                return .failure(error)
            }
            offset += EffectPatch.dataSize
        }

        var tempBank = Bank()
        tempBank.singles = tempSingles
        tempBank.multis = tempMultis
        tempBank.effects = tempEffects
        tempBank.drum = tempDrum
        return .success(tempBank)
    }
    
    public static func nameFor(patchNumber: Int) -> String {
        let bankIndex = patchNumber / 16
        let bankLetter = ["A", "B", "C", "D"][bankIndex]
        let patchIndex = (patchNumber % 16) + 1
        return "\(bankLetter)-\(patchIndex)"
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
    
    /// Gets the length of the data.
    public var dataLength: Int { Bank.dataSize }
}
