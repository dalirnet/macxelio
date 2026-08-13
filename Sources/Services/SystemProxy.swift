import Foundation

enum SystemProxy {
    static func apply(_ enabled: Bool) {
        guard let service = Network.activeService() else { return }
        let host = "127.0.0.1"
        if enabled {
            networksetup("-setwebproxy", service, host, "\(AppConfig.shared.httpPort)")
            networksetup("-setsecurewebproxy", service, host, "\(AppConfig.shared.httpPort)")
            networksetup("-setsocksfirewallproxy", service, host, "\(AppConfig.shared.socksPort)")
        } else {
            networksetup("-setwebproxystate", service, "off")
            networksetup("-setsecurewebproxystate", service, "off")
            networksetup("-setsocksfirewallproxystate", service, "off")
        }
        QUICBlock.apply(enabled)
    }

    private static func networksetup(_ args: String...) {
        Shell.run("/usr/sbin/networksetup", args)
    }
}
