import Foundation

enum Shell {
    @discardableResult
    static func run(_ executable: String, _ args: [String]) -> Bool {
        execute(executable, args, capture: false)?.status == 0
    }

    static func output(_ executable: String, _ args: [String]) -> String {
        execute(executable, args, capture: true)?.output ?? ""
    }

    @discardableResult
    static func runAsRoot(_ shellScript: String) -> Bool {
        if touchIDEnabled, let result = runWithSudo(shellScript) { return result }
        let escaped = shellScript.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return run(
            "/usr/bin/osascript",
            ["-e", "do shell script \"\(escaped)\" with administrator privileges"])
    }

    private static let sudoMarker = "__macxelio_root__"

    private static var touchIDEnabled: Bool {
        guard let text = try? String(contentsOfFile: "/etc/pam.d/sudo_local", encoding: .utf8)
        else { return false }
        return text.split(separator: "\n").contains { line in
            let rule = line.trimmingCharacters(in: .whitespaces)
            return !rule.hasPrefix("#") && rule.contains("pam_tid.so")
        }
    }

    private static func runWithSudo(_ shellScript: String) -> Bool? {
        let script = "echo \(sudoMarker)\n\(shellScript)"
        guard let result = execute("/usr/bin/sudo", ["/bin/sh", "-c", script], capture: true),
            result.output.hasPrefix(sudoMarker)
        else { return nil }
        return result.status == 0
    }

    private static func execute(_ executable: String, _ args: [String], capture: Bool) -> (
        status: Int32, output: String
    )? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        process.standardInput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        let pipe = capture ? Pipe() : nil
        process.standardOutput = pipe ?? FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        let data = pipe?.fileHandleForReading.readDataToEndOfFile() ?? Data()
        process.waitUntilExit()
        return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }
}
