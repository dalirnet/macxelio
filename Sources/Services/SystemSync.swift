import Foundation
import SystemConfiguration

final class SystemSync {
    static let shared = SystemSync()

    private struct Target {
        var proxyPorts: [Int]?
        var dns: Bool
        var firewall: Helper.Firewall
        var tunnel: Bool

        var needsHelper: Bool { dns || tunnel || !firewall.isOff }
    }

    private var service: String?
    private var serviceChanged = true
    private var proxyPorts: [Int]?
    private var dnsPointed = false
    private var declined = false
    private var tunnelOn = false
    private var store: SCDynamicStore?

    func start() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(apply), name: .systemStateDidChange, object: nil)
        watchNetwork()
        Helper.queue.async {
            self.dnsPointed = Helper.isDNSOn
            Helper.stopTunnel()
        }
        apply()
    }

    func retry() {
        Helper.queue.async { self.declined = false }
        apply()
    }

    @objc func apply() {
        let config = AppConfig.shared
        let target = Target(
            proxyPorts: config.systemProxyActive ? [config.httpPort, config.socksPort] : nil,
            dns: config.systemDNSActive,
            firewall: config.firewall,
            tunnel: config.tunnelActive)
        Helper.queue.async { self.reconcile(target) }
    }

    func ensureHelper() -> Bool {
        if Helper.isInstalled() { return true }
        if declined || !Helper.install() {
            declined = true
            DispatchQueue.main.async { self.revert() }
            return false
        }
        return true
    }

    func teardown() {
        Helper.queue.sync {
            if let service {
                if proxyPorts != nil { SystemProxy.disable(service) }
                if dnsPointed { SystemDNS.reset(service) }
            }
            proxyPorts = nil
            dnsPointed = false
            Helper.setFirewall(.off)
            Helper.setDNS(false)
            Helper.stopTunnel()
            tunnelOn = false
        }
    }

    private func reconcile(_ target: Target) {
        updateService()

        if let service, target.proxyPorts != proxyPorts {
            if let ports = target.proxyPorts {
                SystemProxy.enable(service, httpPort: ports[0], socksPort: ports[1])
            } else {
                SystemProxy.disable(service)
            }
            proxyPorts = target.proxyPorts
        }

        if target.needsHelper && !ensureHelper() { return }

        Helper.setFirewall(target.firewall)
        Helper.setDNS(target.dns)
        if let service, target.dns != dnsPointed {
            if target.dns { SystemDNS.point(service) } else { SystemDNS.reset(service) }
            dnsPointed = target.dns
        }

        if target.tunnel != tunnelOn {
            if target.tunnel { Helper.startTunnel() } else { Helper.stopTunnel() }
            tunnelOn = target.tunnel
            DispatchQueue.main.async { Tunnel.shared.monitor(target.tunnel) }
        }
    }

    private func updateService() {
        guard serviceChanged else { return }
        serviceChanged = false
        let current = Network.activeService()
        guard current != service else { return }
        if let old = service {
            if proxyPorts != nil { SystemProxy.disable(old) }
            if dnsPointed { SystemDNS.reset(old) }
            proxyPorts = nil
            dnsPointed = false
        }
        service = current
    }

    private func watchNetwork() {
        var context = SCDynamicStoreContext(
            version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        guard
            let store = SCDynamicStoreCreate(
                nil, "Macxelio" as CFString,
                { _, _, _ in SystemSync.shared.networkDidChange() }, &context)
        else { return }
        SCDynamicStoreSetNotificationKeys(store, ["State:/Network/Global/IPv4"] as CFArray, nil)
        SCDynamicStoreSetDispatchQueue(store, .main)
        self.store = store
    }

    private func networkDidChange() {
        Helper.queue.async { self.serviceChanged = true }
        AppConfig.shared.refresh()
    }

    private func revert() {
        let config = AppConfig.shared
        if config.tunnelEnabled { config.tunnelEnabled = false }
        if config.dnsServerEnabled { config.dnsServerEnabled = false }
    }
}
