import Foundation
import SystemConfiguration

enum Network {
    static func primaryInterface() -> String? {
        let key = "State:/Network/Global/IPv4" as CFString
        guard let store = SCDynamicStoreCreate(nil, "Macxelio" as CFString, nil, nil),
            let value = SCDynamicStoreCopyValue(store, key) as? [String: Any]
        else { return nil }
        return value["PrimaryInterface"] as? String
    }

    static func hasGlobalIPv6() -> Bool {
        guard let iface = primaryInterface() else { return false }
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0, let first = list else { return false }
        defer { freeifaddrs(list) }
        for entry in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let item = entry.pointee
            guard String(cString: item.ifa_name) == iface,
                let addr = item.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET6)
            else { continue }
            let first = addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
                $0.pointee.sin6_addr.__u6_addr.__u6_addr8.0
            }
            if first & 0xE0 == 0x20 { return true }
        }
        return false
    }

    static func portOwner(_ port: Int) -> String? {
        let output = Shell.output(
            "/usr/sbin/lsof", ["-nP", "-iTCP:\(port)", "-sTCP:LISTEN", "-Fcp"])
        let fields = output.split(separator: "\n")
        guard let name = fields.first(where: { $0.hasPrefix("c") })?.dropFirst(),
            let pid = fields.first(where: { $0.hasPrefix("p") })?.dropFirst()
        else { return nil }
        return "\(name) (pid \(pid))"
    }

    static func activeService() -> String? {
        guard let iface = primaryInterface() else { return nil }
        let lines = Shell.output("/usr/sbin/networksetup", ["-listnetworkserviceorder"])
            .components(separatedBy: "\n")
        guard let index = lines.firstIndex(where: { $0.contains("Device: \(iface))") }), index > 0
        else { return nil }
        let name = lines[index - 1].replacingOccurrences(
            of: #"^\(\d+\) "#, with: "", options: .regularExpression)
        return name.isEmpty ? nil : name
    }
}
