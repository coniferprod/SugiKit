#if os(Linux)
import Glibc
#else
import Darwin
#endif

struct StandardErrorOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

var standardError = StandardErrorOutputStream()

struct SugiKit {
    var text = "SugiKit"
}
