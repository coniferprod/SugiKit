#if os(Linux)
import func Glibc.puts
import var Glibc.stderr
#else
import func Darwin.fputs
import var Darwin.stderr
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
