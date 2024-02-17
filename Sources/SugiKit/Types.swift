import Foundation

import SyxPack


// Protocol to wrap an Int guaranteed to be contained in the given closed range.
protocol RangedInt {
    // The current value of the wrapped Int
    var value: Int { get }

    // The range where the Int must be in.
    static var range: ClosedRange<Int> { get }

    // The default value for the Int.
    static var defaultValue: Int { get }

    init()  // initialization with the default value
    init(_ value: Int)  // initialization with a value (will be clamped)
}

extension RangedInt {
    // Gets a random Int value that is inside the range.
    // This is a default implementation.
    static var randomValue: Int {
        return Int.random(in: Self.range)
    }

    // Predicate for checking if a potential value would be inside the range.
    // This is a default implementation.
    static func isValid(value: Int) -> Bool {
        return Self.range.contains(value)
    }

    // Satisfies Equatable conformance.
    // This is a default implementation.
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }
}

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

public struct Depth: Equatable {
    private var _value: Int
}

extension Depth: RangedInt {
    public static let range: ClosedRange<Int> = -50...50

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

public struct Level: Equatable {
    private var _value: Int
}

extension Level: RangedInt {
    public static let range: ClosedRange<Int> = 0...100
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct MIDIChannel: Equatable {
    private var _value: Int
}

extension MIDIChannel: RangedInt {
    public static let range: ClosedRange<Int> = 1...16
    public static let defaultValue = 1

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct Pan: Equatable {
    private var _value: Int
}

extension Pan: RangedInt {
    public static let range: ClosedRange<Int> = -7...7
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct Send1: Equatable {
    private var _value: Int
}

extension Send1: RangedInt {
    public static let range: ClosedRange<Int> = 0...99
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct Send2: Equatable {
    private var _value: Int
}

extension Send2: RangedInt {
    public static let range: ClosedRange<Int> = 0...100
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct EffectParameterSmall: Equatable {
    private var _value: Int
}

extension EffectParameterSmall: RangedInt {
    public static let range: ClosedRange<Int> = 0...7
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct EffectParameterLarge: Equatable {
    private var _value: Int
}

extension EffectParameterLarge: RangedInt {
    public static let range: ClosedRange<Int> = 0...31
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct Resonance: Equatable {
    private var _value: Int
}

extension Resonance: RangedInt {
    public static let range: ClosedRange<Int> = 0...7
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct EffectNumber: Equatable {
    private var _value: Int
}

extension EffectNumber: RangedInt {
    public static let range: ClosedRange<Int> = 1...32
    public static let defaultValue = 1

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct BenderRange: Equatable {
    private var _value: Int
}

extension BenderRange: RangedInt {
    public static let range: ClosedRange<Int> = 0...12  // semitones
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct Coarse: Equatable {
    private var _value: Int
}

extension Coarse: RangedInt {
    public static let range: ClosedRange<Int> = -24...24
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct Fine: Equatable {
    private var _value: Int
}

extension Fine: RangedInt {
    public static let range: ClosedRange<Int> = -50...50
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct Transpose: Equatable {
    private var _value: Int
}

extension Transpose: RangedInt {
    public static let range: ClosedRange<Int> = -24...24
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct InstrumentNumber: Equatable {
    private var _value: Int
}

extension InstrumentNumber: RangedInt {
    public static let range: ClosedRange<Int> = 0...63
    public static let defaultValue = 0

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct WaveNumber: Equatable {
    private var _value: Int
}

extension WaveNumber: RangedInt {
    public static let range: ClosedRange<Int> = 1...256
    public static let defaultValue = 1

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index {
        return Self.allCases.firstIndex(of: self)!
    }
}

public enum PatchKind: String, CaseIterable {
    case unknown
    case single
    case multi
    case effect
    case drum
}

public enum VelocityCurve: Int, Codable, CaseIterable {
    case curve1 = 1
    case curve2
    case curve3
    case curve4
    case curve5
    case curve6
    case curve7
    case curve8

    init?(index: Int) {
        switch index {
        case 1: self = .curve1
        case 2: self = .curve2
        case 3: self = .curve3
        case 4: self = .curve4
        case 5: self = .curve5
        case 6: self = .curve6
        case 7: self = .curve7
        case 8: self = .curve8
        default: return nil
        }
    }
}

public enum KeyScalingCurve: Int, Codable, CaseIterable {
    case curve1 = 1
    case curve2
    case curve3
    case curve4
    case curve5
    case curve6
    case curve7
    case curve8

    init?(index: Int) {
        switch index {
        case 1: self = .curve1
        case 2: self = .curve2
        case 3: self = .curve3
        case 4: self = .curve4
        case 5: self = .curve5
        case 6: self = .curve6
        case 7: self = .curve7
        case 8: self = .curve8
        default: return nil
        }
    }
}

public struct Zone: Codable, Equatable {
    public var low: Int
    public var high: Int
    public var velocitySwitch: VelocitySwitch

    public init() {
        low = 0
        high = 0
        velocitySwitch = .all
    }
}

public enum PlayMode: String, Codable, CaseIterable {
    case keyboard
    case midi
    case mix

    init?(index: Int) {
        switch index {
        case 0: self = .keyboard
        case 1: self = .midi
        case 2: self = .mix
        default: return nil
        }
    }
}

public enum VelocitySwitch: String, Codable, CaseIterable, Equatable {
    case soft
    case loud
    case all

    init?(index: Int) {
        switch index {
        case 0: self = .soft
        case 1: self = .loud
        case 2: self = .all
        default: return nil
        }
    }
}

public enum Submix: String, Codable, CaseIterable, Equatable {
    case a = "a"
    case b = "b"
    case c = "c"
    case d = "d"
    case e = "e"
    case f = "f"
    case g = "g"
    case h = "h"

    init?(index: Int) {
        switch index {
        case 0: self = .a
        case 1: self = .b
        case 2: self = .c
        case 3: self = .d
        case 4: self = .e
        case 5: self = .f
        case 6: self = .g
        case 7: self = .h
        default: return nil
        }
    }
}

public enum SourceMode: String, Codable, CaseIterable {
    case normal
    case twin
    case double

    init?(index: Int) {
        switch index {
        case 0: self = .normal
        case 1: self = .twin
        case 2: self = .double
        default: return nil
        }
    }
}

public enum PolyphonyMode: String, Codable, CaseIterable {
    case poly1
    case poly2
    case solo1
    case solo2

    init?(index: Int) {
        switch index {
        case 0: self = .poly1
        case 1: self = .poly2
        case 2: self = .solo1
        case 3: self = .solo2
        default: return nil
        }
    }
}

public enum WheelAssign: String, Codable, CaseIterable {
    case vibrato
    case lfo
    case cutoff

    init?(index: Int) {
        switch index {
        case 0: self = .vibrato
        case 1: self = .lfo
        case 2: self = .cutoff
        default: return nil
        }
    }
}

public struct AutoBend: Equatable, CustomStringConvertible {
    public var time: Level  // 0~100
    public var depth: Depth  // -50~+50
    public var keyScalingTime: Depth  // -50~+50
    public var velocityDepth: Depth  // -50~+50

    public init() {
        time = Level()
        depth = Depth()
        keyScalingTime = Depth()
        velocityDepth = Depth()
    }

    public init(time: Int, depth: Int, keyScalingTime: Int, velocityDepth: Int) {
        self.time = Level(time)
        self.depth = Depth(depth)
        self.keyScalingTime = Depth(keyScalingTime)
        self.velocityDepth = Depth(velocityDepth)
    }

    public static func parse(from data: ByteArray) -> Result<AutoBend, ParseError> {
        var offset = 0
        var b: Byte = 0x00

        var temp = AutoBend()

        b = data.next(&offset)
        temp.time = Level(Int(b & 0x7f))

        b = data.next(&offset)
        temp.depth = Depth(Int((b & 0x7f)) - 50) // 0~100 to ±50

        b = data.next(&offset)
        temp.keyScalingTime = Depth(Int((b & 0x7f)) - 50) // 0~100 to ±50

        b = data.next(&offset)
        temp.velocityDepth = Depth(Int((b & 0x7f)) - 50) // 0~100 to ±50

        return .success(temp)
    }

    public var description: String {
        return "Auto bend settings: time = \(time), depth = \(depth), KS time = \(keyScalingTime), vel depth = \(velocityDepth)"
    }
    
    private var data: ByteArray {
        var buf = ByteArray()
        buf.append(contentsOf: [
            Byte(self.time.value),
            Byte(self.depth.value + 50),
            Byte(self.keyScalingTime.value + 50),
            Byte(self.velocityDepth.value + 50)
        ])
        return buf
    }
    
    public static let dataSize = 4
    
    public static func ==(lhs: AutoBend, rhs: AutoBend) -> Bool {
        return lhs.time == rhs.time &&
            lhs.depth == rhs.depth &&
            lhs.keyScalingTime == rhs.keyScalingTime &&
            lhs.velocityDepth == rhs.velocityDepth
    }
}


public struct LevelModulation: Equatable, CustomStringConvertible {
    public var velocityDepth: Depth
    public var pressureDepth: Depth
    public var keyScalingDepth: Depth

    public init() {
        velocityDepth = Depth()
        pressureDepth = Depth()
        keyScalingDepth = Depth()
    }

    public init(velocityDepth: Int, pressureDepth: Int, keyScalingDepth: Int) {
        self.velocityDepth = Depth(velocityDepth)
        self.pressureDepth = Depth(pressureDepth)
        self.keyScalingDepth = Depth(keyScalingDepth)
    }

    public static func parse(from data: ByteArray) -> Result<LevelModulation, ParseError> {
        var offset = 0
        var b: Byte = 0x00

        var temp = LevelModulation()

        b = data.next(&offset)
        temp.velocityDepth = Depth(Int(b) - 50)

        b = data.next(&offset)
        temp.pressureDepth = Depth(Int(b) - 50)

        b = data.next(&offset)
        temp.keyScalingDepth = Depth(Int(b) - 50)

        return .success(temp)
    }

    private var data: ByteArray {
        var buf = ByteArray()
        buf.append(contentsOf: [
            Byte(self.velocityDepth.value + 50),
            Byte(self.pressureDepth.value + 50),
            Byte(self.keyScalingDepth.value + 50)
        ])
        return buf
    }

    public static let dataSize = 3

    public var description: String {
        return "Vel.depth=\(velocityDepth) Prs.depth=\(pressureDepth) KSDepth=\(keyScalingDepth)"
    }

    public static func ==(lhs: LevelModulation, rhs: LevelModulation) -> Bool {
        return lhs.velocityDepth == rhs.velocityDepth &&
            lhs.pressureDepth == rhs.pressureDepth &&
            lhs.keyScalingDepth == rhs.keyScalingDepth
    }
}

public struct TimeModulation: Equatable, CustomStringConvertible {
    public var attackVelocity: Depth
    public var releaseVelocity: Depth
    public var keyScaling: Depth

    public init() {
        attackVelocity = Depth()
        releaseVelocity = Depth()
        keyScaling = Depth()
    }

    public init(attackVelocity: Int, releaseVelocity: Int, keyScaling: Int) {
        self.attackVelocity = Depth(attackVelocity)
        self.releaseVelocity = Depth(releaseVelocity)
        self.keyScaling = Depth(keyScaling)
    }

    public static func parse(from data: ByteArray) -> Result<TimeModulation, ParseError> {
        var offset = 0
        var b: Byte = 0x00

        var temp = TimeModulation()

        b = data.next(&offset)
        let attack = Int(b) - 50
        if Depth.isValid(value: attack) {
            temp.attackVelocity = Depth(attack)
        }
        else {
            return .failure(.invalidData(offset))
        }

        b = data.next(&offset)
        let release = Int(b) - 50
        if Depth.isValid(value: release) {
            temp.releaseVelocity = Depth(release)
        }
        else {
            return .failure(.invalidData(offset))
        }

        b = data.next(&offset)
        let ks = Int(b) - 50
        if Depth.isValid(value: ks) {
            temp.keyScaling = Depth(ks)
        }
        else {
            return .failure(.invalidData(offset))
        }

        return .success(temp)
    }

    private var data: ByteArray {
        var buf = ByteArray()
        buf.append(contentsOf: [
            Byte(self.attackVelocity.value + 50),
            Byte(self.releaseVelocity.value + 50),
            Byte(self.keyScaling.value + 50)
        ])
        return buf
    }

    public static let dataSize = 3

    public var description: String {
        return "AtkVel=\(attackVelocity) RelVel=\(releaseVelocity) KS=\(keyScaling)"
    }

    public static func ==(lhs: TimeModulation, rhs: TimeModulation) -> Bool {
        return lhs.attackVelocity == rhs.attackVelocity &&
            lhs.releaseVelocity == rhs.releaseVelocity &&
            lhs.keyScaling == rhs.keyScaling
    }
}

/// Key with note number and name.
public struct Key: Codable, Equatable, CustomStringConvertible {
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    public var note: Int

    /// Name of the key.
    public var name: String {
        let octave = self.note / 12 - 1
        let name = Key.noteNames[self.note % 12]
        return "\(name)\(octave)"
    }

    /// Initialize the key with a note number.
    public init(note: Int) {
        self.note = note
    }

    /// Get the key corresponding to a note name.
    public static func key(for name: String) -> Key? {
        let notes = CharacterSet(charactersIn: "CDEFGAB")

        var i = 0
        var notePart = ""
        var octavePart = ""
        while i < name.count {
            let c = name[i ..< i + 1]

            let isNote = c.unicodeScalars.allSatisfy { notes.contains($0) }
            if isNote {
                notePart += c
            }
            else {
                return nil
            }

            if c == "#" {
                notePart += c
            }
            if c == "-" {
                octavePart += c
            }

            let isDigit = c.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
            if isDigit {
                octavePart += c
            }

            i += 1
        }

        if let octave = Int(octavePart), let noteIndex = Key.noteNames.firstIndex(where: { $0 == notePart }) {
            return Key(note: (octave + 1) * 12 + noteIndex)
        }

        return nil
    }

    public var description: String {
        return self.name
    }
}

// MARK: - SystemExclusiveData conformance

extension AutoBend: SystemExclusiveData {
    public func asData() -> ByteArray {
        return self.data
    }

    public var dataLength: Int { AutoBend.dataSize }
}

extension LevelModulation: SystemExclusiveData {
    /// Gets the level modulation data as MIDI System Exclusive data bytes.
    public func asData() -> ByteArray {
        return self.data
    }

    /// Gets the length of the level modulation data.
    public var dataLength: Int { LevelModulation.dataSize }
}

extension TimeModulation: SystemExclusiveData {
    /// Gets the time modulation data as MIDI System Exclusive data bytes.
    public func asData() -> ByteArray {
        return self.data
    }

    /// Gets the length of the time modulation data.
    public var dataLength: Int { TimeModulation.dataSize }
}
