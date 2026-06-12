import Foundation

enum Network {
    static func activeService() -> String? {
        let script = #"""
            IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
            networksetup -listnetworkserviceorder | grep -B1 "Device: $IFACE)" | head -1 | sed -E 's/^\([0-9]+\) //'
            """#
        let output = Shell.output("/bin/zsh", ["-c", script])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return output.isEmpty ? nil : output
    }
}
