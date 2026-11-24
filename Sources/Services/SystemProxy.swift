import Foundation

enum SystemProxy {
    private static let host = "127.0.0.1"

    static func enable(_ service: String, httpPort: Int, socksPort: Int) {
        networksetup("-setwebproxy", service, host, "\(httpPort)")
        networksetup("-setsecurewebproxy", service, host, "\(httpPort)")
        networksetup("-setsocksfirewallproxy", service, host, "\(socksPort)")
    }

    static func disable(_ service: String) {
        networksetup("-setwebproxystate", service, "off")
        networksetup("-setsecurewebproxystate", service, "off")
        networksetup("-setsocksfirewallproxystate", service, "off")
    }

    private static func networksetup(_ args: String...) {
        Shell.run("/usr/sbin/networksetup", args)
    }
}
