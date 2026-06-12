import AppKit

extension AppDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        buildMenu(menu)
    }

    private func buildMenu(_ menu: NSMenu) {
        menu.addItem(openMenuItem())
        menu.addItem(.separator())

        menu.addItem(
            parentItem(
                "Proxy Mode",
                image: MenuIcon.circle(for: appConfig.proxyMode),
                submenu: proxyModeSubmenu()))
        menu.addItem(.separator())

        menu.addItem(
            parentItem(
                "System Proxy",
                image: MenuIcon.circle(filled: appConfig.systemProxyEnabled),
                submenu: toggleSubmenu(
                    current: appConfig.systemProxyEnabled, action: #selector(setSystemProxy(_:)))))
        menu.addItem(
            parentItem(
                "System DNS",
                image: MenuIcon.circle(filled: appConfig.dnsServerEnabled),
                submenu: toggleSubmenu(
                    current: appConfig.dnsServerEnabled, action: #selector(setSystemDNS(_:)))))
        menu.addItem(.separator())

        for page in MenuPage.allCases {
            menu.addItem(pageItem(page))
        }
        menu.addItem(.separator())

        menu.addItem(quitMenuItem())
    }

    private func openMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.title =
            appConfig.proxies.first { $0.id == appConfig.selectedProxyId }?.name
            ?? "No Proxy"
        if !appConfig.proxies.isEmpty {
            item.submenu = proxySubmenu()
        }
        let status = MainActor.assumeIsolated { ConnectivityChecker.shared.status }
        applyStatus(status, to: item)
        statusMenuItem = item
        return item
    }

    func refreshStatusMenuItem(_ status: ConnectivityChecker.Status) {
        if let item = statusMenuItem {
            applyStatus(status, to: item)
        }
    }

    private func applyStatus(_ status: ConnectivityChecker.Status, to item: NSMenuItem) {
        item.image = MenuIcon.statusIcon(for: status)
        guard #available(macOS 14.0, *) else { return }
        if let text = status.latencyText {
            item.badge = NSMenuItemBadge(string: text)
        } else {
            item.badge = nil
        }
    }

    private func proxySubmenu() -> NSMenu {
        let submenu = NSMenu()
        for proxy in appConfig.proxies {
            let item = NSMenuItem()
            item.title = proxy.name
            item.state = appConfig.selectedProxyId == proxy.id ? .on : .off
            item.representedObject = proxy.id
            item.target = self
            item.action = #selector(selectProxy(_:))
            submenu.addItem(item)
        }
        return submenu
    }

    private func pageItem(_ page: MenuPage) -> NSMenuItem {
        let item = NSMenuItem()
        item.title = page.title
        item.image = MenuIcon.symbol(page.symbol)
        item.representedObject = page.notification
        item.target = self
        item.action = #selector(openPage(_:))
        item.keyEquivalent = page.key
        item.keyEquivalentModifierMask = [.command, .shift]
        return item
    }

    private func proxyModeSubmenu() -> NSMenu {
        let submenu = NSMenu()
        for mode in AppConfig.ProxyMode.allCases {
            let item = NSMenuItem()
            item.title = mode.rawValue
            item.state = appConfig.proxyMode == mode ? .on : .off
            item.representedObject = mode
            item.target = self
            item.action = #selector(setProxyMode(_:))
            submenu.addItem(item)
        }
        return submenu
    }

    private func toggleSubmenu(current: Bool, action: Selector) -> NSMenu {
        let submenu = NSMenu()
        for enabled in [true, false] {
            let item = NSMenuItem()
            item.title = enabled ? "Enabled" : "Disabled"
            item.state = current == enabled ? .on : .off
            item.representedObject = enabled
            item.target = self
            item.action = action
            submenu.addItem(item)
        }
        return submenu
    }

    private func quitMenuItem() -> NSMenuItem {
        let item = actionItem("Quit Macxelio", action: #selector(quitApp))
        item.keyEquivalent = "q"
        item.keyEquivalentModifierMask = .command
        return item
    }

    private func parentItem(_ title: String, image: NSImage?, submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem()
        item.title = title
        item.image = image
        item.submenu = submenu
        return item
    }

    private func actionItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem()
        item.title = title
        item.target = self
        item.action = action
        return item
    }

    @objc func setProxyMode(_ sender: NSMenuItem) {
        if let mode = sender.representedObject as? AppConfig.ProxyMode {
            appConfig.proxyMode = mode
        }
    }

    @objc func setSystemProxy(_ sender: NSMenuItem) {
        if let enabled = sender.representedObject as? Bool {
            appConfig.systemProxyEnabled = enabled
            SystemProxy.apply(enabled)
        }
    }

    @objc func setSystemDNS(_ sender: NSMenuItem) {
        if let enabled = sender.representedObject as? Bool {
            appConfig.dnsServerEnabled = enabled
            DispatchQueue.global().async {
                let success = enabled ? SystemDNS.enable() : SystemDNS.disable()
                if !success {
                    DispatchQueue.main.async {
                        self.appConfig.dnsServerEnabled = !enabled
                    }
                }
            }
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    @objc func selectProxy(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID, appConfig.selectedProxyId != id else {
            return
        }
        appConfig.selectedProxyId = id
        MainActor.assumeIsolated { ConnectivityChecker.shared.check() }
    }

    @objc func openPage(_ sender: NSMenuItem) {
        guard let notification = sender.representedObject as? Notification.Name else { return }
        openMainWindow()
        NotificationCenter.default.post(name: notification, object: nil)
    }
}

enum MenuPage: CaseIterable {
    case proxies
    case rules
    case hosts
    case environments
    case connections

    var title: String {
        switch self {
        case .proxies: return "Proxies"
        case .rules: return "Rules"
        case .hosts: return "Hosts"
        case .environments: return "Environments"
        case .connections: return "Connections"
        }
    }

    var symbol: String {
        switch self {
        case .proxies: return "bolt"
        case .rules: return "signpost.right.and.left"
        case .hosts: return "server.rack"
        case .environments: return "square.grid.2x2"
        case .connections: return "network"
        }
    }

    var key: String {
        switch self {
        case .proxies: return "p"
        case .rules: return "r"
        case .hosts: return "h"
        case .environments: return "e"
        case .connections: return "c"
        }
    }

    var notification: Notification.Name {
        switch self {
        case .proxies: return .openMain
        case .rules: return .openRules
        case .hosts: return .openHosts
        case .environments: return .openEnvironments
        case .connections: return .openConnections
        }
    }
}
