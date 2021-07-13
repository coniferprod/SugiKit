# SugiKit

Patch data model and System Exclusive message parser generator for the Kawai K4 digital synthesizer.

## Implementation notes

### Helper types

The System Exclusive messages deal in bytes and byte arrays. To make it explicit
and to avoid typing, the following typealias definitions are used:

    public typealias Byte = UInt8
    public typealias ByteArray = [Byte]


### Enumerated types

Many of the synth parameter values are modeled with enumerated types.
To make the parsing of System Exclusive messages easier the types have an
optional initializer that takes an integer value representing the corresponding byte from
SysEx. For example, the `LFO.Shape` type has: 

    init?(index: Int) {
        switch index {
        case 0: self = .triangle
        case 1: self = .sawtooth
        case 2: self = .square
        case 3: self = .random
        default: return nil
        }
    }

If the value passed in represents a valid enumeration case, it is used for initializing
the object. Otherwise `nil` is returned.

To make generating SysEx messages easier, these enumerated types conform to the
`CaseIterable` protocol which has been extended with a method that returns the
index of the enumeration value:

    extension CaseIterable where Self: Equatable {
        var index: Self.AllCases.Index? {
            return Self.allCases.firstIndex { self == $0 }
        }
    }

Why this instead of `rawValue`? Can't remember.

### Generating System Exclusive messages

Most synth blocks have a computed property `data` that provides the raw
bytes needed for the generated System Exclusive message. It returns the bytes
in the required format as a `ByteArray`.

The actual SysEx message is constructed using the computed property
`systemExclusiveData`, which collects the bytes using the `data` property
and adds the checksum:

    public var systemExclusiveData: ByteArray {
        var buf = ByteArray()
        let d = self.data
        buf.append(contentsOf: d)
        buf.append(checksum(bytes: d))
        return buf
    }

