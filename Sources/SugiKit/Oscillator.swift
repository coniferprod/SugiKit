import Foundation

public struct Oscillator: Codable, CustomStringConvertible {
    public var waveNumber: Int
    public var keyTrack:  Bool
    public var coarse: Int  // -24~+24
    public var fine: Int  // -50~+50
    public var fixedKey: String  // C-1 to G8
    public var pressureFrequency: Bool
    public var vibrato: Bool
    
    public init() {
        waveNumber = 10
        keyTrack = true
        coarse = 0
        fine = 0
        fixedKey = "C4"
        pressureFrequency = true
        vibrato = true
    }
    
    public var description: String {
        var lines = [String]()
        
        let waveName = Wave(number: waveNumber).name
        lines.append("Wave = \(waveNumber)  \(waveName)")
        lines.append("Key track = \(keyTrack)")
        lines.append("Coarse = \(coarse)  Fine = \(fine)")
        lines.append("Fixed key = \(fixedKey)")
        lines.append("Pressure freq. = \(pressureFrequency)")
        lines.append("Vibrato = \(vibrato)")
        return lines.joined(separator: "\n")
    }
}
