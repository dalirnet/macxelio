import Foundation
import Network

enum Validator {
    static func portError(_ value: String) -> String? {
        guard let port = Int(value) else { return "Port must be a number." }
        guard (1...65535).contains(port) else { return "Port must be between 1 and 65535." }
        return nil
    }

    static func ipError(_ value: String) -> String? {
        isIP(value) ? nil : "Enter a valid IP address."
    }

    static func ipOrCIDRError(_ value: String) -> String? {
        isIP(value) || isCIDR(value) ? nil : "Enter a valid IP or CIDR (e.g. 10.0.0.0/8)."
    }

    static func domainError(_ value: String) -> String? {
        isDomain(value) ? nil : "Enter a valid domain (e.g. example.com)."
    }

    static func hostError(_ value: String) -> String? {
        isIP(value) || isDomain(value) ? nil : "Enter a valid domain or IP address."
    }

    static func codeError(_ value: String) -> String? {
        matches(value, #"^[a-zA-Z0-9_-]+$"#) ? nil : "Use letters, numbers, or dashes only."
    }

    static func uuidError(_ value: String) -> String? {
        UUID(uuidString: value) != nil ? nil : "Enter a valid UUID."
    }

    static func isIP(_ value: String) -> Bool {
        IPv4Address(value) != nil || IPv6Address(value) != nil
    }

    static func isCIDR(_ value: String) -> Bool {
        let parts = value.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, let prefix = Int(parts[1]) else { return false }
        let host = String(parts[0])
        if IPv4Address(host) != nil { return (0...32).contains(prefix) }
        if IPv6Address(host) != nil { return (0...128).contains(prefix) }
        return false
    }

    static func isDomain(_ value: String) -> Bool {
        matches(value, #"^(\*\.)?([a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,}$"#)
    }

    private static func matches(_ value: String, _ pattern: String) -> Bool {
        value.range(of: pattern, options: .regularExpression) != nil
    }
}
