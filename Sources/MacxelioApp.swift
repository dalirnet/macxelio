import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var statusMenu: NSMenu?

    let appConfig = AppConfig.shared
    let xrayCore = XrayCore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start xray service when app launches (if installed)
        if xrayCore.isInstalled() {
            appConfig.save()
            xrayCore.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        xrayCore.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            let image = FlameIcon.createMenuBarImage(size: 18)
            image.isTemplate = true
            button.image = image
        }

        statusMenu = NSMenu()
        statusMenu?.delegate = self
        statusItem?.menu = statusMenu
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        buildMenu(menu)
    }

    private func buildMenu(_ menu: NSMenu) {
        // Proxy mode submenu
        let modeItem = NSMenuItem()
        modeItem.title = "Proxy Mode"
        let modeSubmenu = NSMenu()
        for mode in AppConfig.ProxyMode.allCases {
            let item = NSMenuItem()
            item.title = mode.rawValue
            item.state = appConfig.proxyMode == mode ? .on : .off
            item.representedObject = mode
            item.target = self
            item.action = #selector(setProxyMode(_:))
            modeSubmenu.addItem(item)
        }
        modeItem.submenu = modeSubmenu
        menu.addItem(modeItem)

        menu.addItem(NSMenuItem.separator())

        // Config list
        if !appConfig.configs.isEmpty {
            for config in appConfig.configs {
                let item = NSMenuItem()
                item.title = config.name
                item.state = appConfig.selectedConfigId == config.id ? .on : .off
                item.representedObject = config.id
                item.target = self
                item.action = #selector(selectConfig(_:))

                if let ping = config.ping {
                    item.title = "\(config.name)  —  \(ping)ms"
                }

                menu.addItem(item)
            }
            menu.addItem(NSMenuItem.separator())
        }

        // System Proxy toggle
        let systemProxyItem = NSMenuItem()
        systemProxyItem.title = "System Proxy"
        systemProxyItem.state = appConfig.systemProxyEnabled ? .on : .off
        systemProxyItem.target = self
        systemProxyItem.action = #selector(toggleSystemProxy)
        menu.addItem(systemProxyItem)

        // DNS Server toggle
        let dnsItem = NSMenuItem()
        dnsItem.title = "DNS Server"
        dnsItem.state = appConfig.dnsServerEnabled ? .on : .off
        dnsItem.target = self
        dnsItem.action = #selector(toggleDNS)
        menu.addItem(dnsItem)

        menu.addItem(NSMenuItem.separator())

        // Copy proxy command
        let copyItem = NSMenuItem()
        copyItem.title = "Copy Proxy Command"
        copyItem.target = self
        copyItem.action = #selector(copyProxyCommand)
        menu.addItem(copyItem)

        menu.addItem(NSMenuItem.separator())

        // Quick access items
        let dnsViewItem = NSMenuItem()
        dnsViewItem.title = "DNS"
        dnsViewItem.target = self
        dnsViewItem.action = #selector(openDNS)
        menu.addItem(dnsViewItem)

        let configsItem = NSMenuItem()
        configsItem.title = "Configs"
        configsItem.target = self
        configsItem.action = #selector(openConfigs)
        menu.addItem(configsItem)

        let rulesItem = NSMenuItem()
        rulesItem.title = "Rules"
        rulesItem.target = self
        rulesItem.action = #selector(openRules)
        menu.addItem(rulesItem)

        let settingsItem = NSMenuItem()
        settingsItem.title = "Settings"
        settingsItem.target = self
        settingsItem.action = #selector(openSettings)
        settingsItem.keyEquivalent = ","
        settingsItem.keyEquivalentModifierMask = .command
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem()
        quitItem.title = "Quit Macxelio"
        quitItem.target = self
        quitItem.action = #selector(quitApp)
        quitItem.keyEquivalent = "q"
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc func setProxyMode(_ sender: NSMenuItem) {
        if let mode = sender.representedObject as? AppConfig.ProxyMode {
            appConfig.proxyMode = mode
        }
    }

    @objc func selectConfig(_ sender: NSMenuItem) {
        if let configId = sender.representedObject as? UUID {
            if appConfig.selectedConfigId == configId {
                appConfig.selectedConfigId = nil
            } else {
                appConfig.selectedConfigId = configId
            }
        }
    }

    @objc func toggleSystemProxy() {
        appConfig.systemProxyEnabled.toggle()
    }

    @objc func toggleDNS() {
        appConfig.dnsServerEnabled.toggle()
    }

    @objc func copyProxyCommand() {
        let command = """
            export http_proxy=http://127.0.0.1:\(appConfig.httpPort)
            export https_proxy=http://127.0.0.1:\(appConfig.httpPort)
            """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
    }

    @objc func openConfigs() {
        openMainWindow()
        NotificationCenter.default.post(name: .addConfig, object: nil)
    }

    @objc func openRules() {
        openMainWindow()
        NotificationCenter.default.post(name: .openRules, object: nil)
    }

    @objc func openDNS() {
        openMainWindow()
        NotificationCenter.default.post(name: .openDNS, object: nil)
    }

    @objc func openConnections() {
        openMainWindow()
        NotificationCenter.default.post(name: .openConnections, object: nil)
    }

    @objc func openSettings() {
        openMainWindow()
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    private func openMainWindow() {
        for window in NSApp.windows {
            if window.contentView != nil && !window.title.contains("Item") {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
    }
}

@main
struct MacxelioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var setupStep: SetupStep = .checking

    enum SetupStep {
        case checking
        case prepare
        case configuration
        case ready
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch setupStep {
                case .checking:
                    EmptyView()
                case .prepare:
                    PrepareView {
                        setupStep = .configuration
                    }
                case .configuration:
                    ConfigurationView {
                        setupStep = .ready
                        appDelegate.appConfig.save()
                        appDelegate.xrayCore.start()
                        appDelegate.setupStatusBar()
                    }
                case .ready:
                    MainView(
                        appConfig: appDelegate.appConfig,
                        xrayCore: appDelegate.xrayCore
                    )
                }
            }
            .onAppear {
                checkXrayAvailability()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(replacing: .appTermination) {
                Button("Quit Macxelio") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }

            CommandGroup(replacing: .help) {
                Button("Macxelio Help") {
                    NotificationCenter.default.post(name: .openHelp, object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
                .disabled(setupStep != .ready)
            }

            CommandGroup(after: .newItem) {
                Button(action: {
                    NotificationCenter.default.post(name: .openConnections, object: nil)
                }) {
                    Label("Connections", systemImage: "network")
                }
                .disabled(setupStep != .ready)

                Button(action: {
                    NotificationCenter.default.post(name: .openRules, object: nil)
                }) {
                    Label("Rules", systemImage: "list.bullet.rectangle")
                }
                .disabled(setupStep != .ready)

                Button(action: {
                    NotificationCenter.default.post(name: .openDNS, object: nil)
                }) {
                    Label("DNS", systemImage: "server.rack")
                }
                .disabled(setupStep != .ready)

                Divider()

                Button(action: {
                    NotificationCenter.default.post(name: .openAppUpdate, object: nil)
                }) {
                    Label("App Update", systemImage: "arrow.down.app")
                }
                .disabled(setupStep != .ready)

                Button(action: {
                    NotificationCenter.default.post(name: .openXrayUpdate, object: nil)
                }) {
                    Label("Xray Update", systemImage: "shippingbox")
                }
                .disabled(setupStep != .ready)

                Divider()

                Button(action: {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }) {
                    Label("Settings", systemImage: "gearshape")
                }
                .keyboardShortcut(",", modifiers: .command)
                .disabled(setupStep != .ready)
            }
        }
    }

    private func checkXrayAvailability() {
        if appDelegate.xrayCore.isInstalled() {
            setupStep = .ready
            appDelegate.setupStatusBar()
        } else {
            setupStep = .prepare
        }
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
    static let addConfig = Notification.Name("addConfig")
    static let openHelp = Notification.Name("openHelp")
    static let openAppUpdate = Notification.Name("openAppUpdate")
    static let openXrayUpdate = Notification.Name("openXrayUpdate")
    static let openConnections = Notification.Name("openConnections")
    static let openRules = Notification.Name("openRules")
    static let openDNS = Notification.Name("openDNS")
}
