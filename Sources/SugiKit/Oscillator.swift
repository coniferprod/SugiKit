import Foundation

public struct Oscillator: Codable {
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
}
