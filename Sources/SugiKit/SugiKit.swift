import func Darwin.fputs
import var Darwin.stderr

struct StandardErrorOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

var standardError = StandardErrorOutputStream()

struct SugiKit {
    var text = "SugiKit"
}
