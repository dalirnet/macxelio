import AppKit

extension AppDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        buildMenu(menu)
    }

    private func buildMenu(_ menu: NSMenu) {
        menu.autoenablesItems = false
        menu.addItem(openMenuItem())
        menu.addItem(.separator())

        menu.addItem(
            parentItem(
                "Proxy Mode",
                image: MenuIcon.circle(for: appConfig.proxyMode),
                submenu: proxyModeSubmenu()))
        menu.addItem(.separator())

        let locked = appConfig.tunnelEnabled
        menu.addItem(
            toggleItem(
                "System Tunnel", current: appConfig.tunnelEnabled,
                action: #selector(setTunnel(_:))))
        menu.addItem(
            toggleItem(
                "System Proxy", current: appConfig.systemProxyActive, locked: locked,
                action: #selector(setSystemProxy(_:))))
        menu.addItem(
            toggleItem(
                "System DNS", current: appConfig.systemDNSActive, locked: locked,
                action: #selector(setSystemDNS(_:))))
        menu.addItem(.separator())

        for page in MenuPage.allCases {
            menu.addItem(
                pageItem(
                    page.title, symbol: page.symbol, notification: page.notification,
                    key: page.key, modifiers: [.command, .shift]))
        }
        menu.addItem(.separator())

        menu.addItem(
            pageItem(
                "Settings", symbol: "gearshape", notification: .openSettings, key: ",",
                modifiers: .command))
        menu.addItem(.separator())

        menu.addItem(quitMenuItem())

    }

    private func openMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.title = appConfig.selectedProxy?.name ?? "No Proxy"
        if !appConfig.proxies.isEmpty {
            item.submenu = proxySubmenu()
        }
        let status = MainActor.assumeIsolated { ConnectivityChecker.shared.status }
        applyStatus(displayStatus(for: status), to: item)
        statusMenuItem = item
        return item
    }

    func refreshStatusMenuItem(_ status: ConnectivityChecker.Status) {
        if case .checking = status {} else { lastResolvedStatus = status }
        if let item = statusMenuItem {
            applyStatus(displayStatus(for: status), to: item)
        }
    }

    private func displayStatus(for status: ConnectivityChecker.Status) -> ConnectivityChecker.Status
    {
        if case .checking = status { return lastResolvedStatus }
        return status
    }

    private func applyStatus(_ status: ConnectivityChecker.Status, to item: NSMenuItem) {
        item.image = MenuIcon.statusIcon(for: status)
        MenuIcon.keepVisible(item)
        guard #available(macOS 14.0, *) else { return }
        item.badge = status.latencyText.map { NSMenuItemBadge(string: $0) }
    }

    private func proxySubmenu() -> NSMenu {
        let submenu = NSMenu()
        submenu.addItem(checkMenuItem())
        submenu.addItem(.separator())
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

    private func checkMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.view = MenuActionRow(
            title: "Check Now", target: self, action: #selector(checkConnectivity))
        return item
    }

    private func pageItem(
        _ title: String, symbol: String, notification: Notification.Name, key: String,
        modifiers: NSEvent.ModifierFlags
    ) -> NSMenuItem {
        let item = actionItem(title, action: #selector(openPage(_:)))
        item.image = MenuIcon.symbol(symbol)
        item.representedObject = notification
        item.keyEquivalent = key
        item.keyEquivalentModifierMask = modifiers
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

    private func toggleItem(
        _ title: String, current: Bool, locked: Bool = false, action: Selector
    ) -> NSMenuItem {
        let item = parentItem(
            title, image: MenuIcon.circle(filled: current),
            submenu: toggleSubmenu(current: current, action: action))
        if locked {
            item.isEnabled = false
            item.toolTip = "Managed by System Tunnel"
        }
        return item
    }

    private func toggleSubmenu(current: Bool, action: Selector) -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false
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
        MenuIcon.keepVisible(item)
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

    @objc func setTunnel(_ sender: NSMenuItem) {
        if sender.representedObject as? Bool == true && !Tunnel.isSupported {
            Tunnel.shared.updateXray()
            return
        }
        setToggle(sender, \.tunnelEnabled)
    }

    @objc func setSystemProxy(_ sender: NSMenuItem) {
        setToggle(sender, \.systemProxyEnabled)
    }

    @objc func setSystemDNS(_ sender: NSMenuItem) {
        setToggle(sender, \.dnsServerEnabled)
    }

    private func setToggle(
        _ sender: NSMenuItem, _ keyPath: ReferenceWritableKeyPath<AppConfig, Bool>
    ) {
        guard let enabled = sender.representedObject as? Bool else { return }
        SystemSync.shared.retry()
        appConfig[keyPath: keyPath] = enabled
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    @objc func checkConnectivity() {
        MainActor.assumeIsolated { ConnectivityChecker.shared.check() }
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
