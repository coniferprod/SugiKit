import Foundation

open class HashableClass {
    public init() {}
}

// MARK: - Hashable

extension HashableClass: Hashable {
    public func hash(into hasher: inout Hasher) {
         hasher.combine(ObjectIdentifier(self).hashValue)
    }
}

// MARK: - Equatable

extension HashableClass: Equatable {
    public static func ==(lhs: HashableClass, rhs: HashableClass) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
