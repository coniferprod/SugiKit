import Foundation

func checksum(bytes: ByteArray) -> Byte {
    var totalSum = bytes.reduce(0) { $0 + (Int($1) & 0xff) }
    totalSum += 0xa5
    return Byte(totalSum & 0x7f)
}
