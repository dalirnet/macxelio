import Foundation

enum SystemProxy {
    static func apply(_ enabled: Bool) {
        guard let service = Network.activeService() else { return }
        let host = "127.0.0.1"
        if enabled {
            networksetup("-setwebproxy", service, host, "\(AppConfig.httpPort)")
            networksetup("-setsecurewebproxy", service, host, "\(AppConfig.httpPort)")
            networksetup("-setsocksfirewallproxy", service, host, "\(AppConfig.socksPort)")
        } else {
            networksetup("-setwebproxystate", service, "off")
            networksetup("-setsecurewebproxystate", service, "off")
            networksetup("-setsocksfirewallproxystate", service, "off")
        }
    }

    private static func networksetup(_ args: String...) {
        Shell.run("/usr/sbin/networksetup", args)
    }
}
