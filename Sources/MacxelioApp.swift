import Combine
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    var statusMenu: NSMenu?
    private var statusObserver: AnyCancellable?
    private var blinkTimer: Timer?

    let appConfig = AppConfig.shared
    let xrayCore = XrayCore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if xrayCore.isInstalled() {
            appConfig.save()
            xrayCore.start()
            if appConfig.systemProxyEnabled { SystemProxy.apply(true) }
            if appConfig.dnsServerEnabled {
                DispatchQueue.global().async {
                    if !SystemDNS.enable() {
                        DispatchQueue.main.async { self.appConfig.dnsServerEnabled = false }
                    }
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if appConfig.systemProxyEnabled { SystemProxy.apply(false) }
        if SystemDNS.isInstalled() { SystemDNS.disable() }
        xrayCore.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @MainActor
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            let image = FlameIcon.createMenuBarImage(size: 20)
            image.isTemplate = true
            button.image = image
        }

        statusMenu = NSMenu()
        statusMenu?.delegate = self
        statusItem?.menu = statusMenu

        ConnectivityChecker.shared.start()
        statusObserver = ConnectivityChecker.shared.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in self?.updateStatusAppearance(status) }

        configureMainWindow()
    }

    private func updateStatusAppearance(_ status: ConnectivityChecker.Status) {
        guard status == .checking else {
            blinkTimer?.invalidate()
            blinkTimer = nil
            if case .ok = status {
                statusItem?.button?.alphaValue = 1.0
            } else {
                statusItem?.button?.alphaValue = 0.5
            }
            return
        }
        guard blinkTimer == nil else { return }
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            guard let button = self?.statusItem?.button else { return }
            let target: CGFloat = button.alphaValue < 1 ? 1.0 : 0.5
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.35
                button.animator().alphaValue = target
            }
        }
    }

    private func mainWindow() -> NSWindow? {
        NSApp.windows.first { $0.contentView != nil && !$0.title.contains("Item") }
    }

    private func configureMainWindow() {
        guard let window = mainWindow() else { return }
        window.isReleasedWhenClosed = false
        window.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        buildMenu(menu)
    }

    private func buildMenu(_ menu: NSMenu) {
        let openItem = NSMenuItem()
        openItem.title = "Open Macxelio"
        openItem.target = self
        openItem.action = #selector(openMainWindow)
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

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

        let systemProxyItem = NSMenuItem()
        systemProxyItem.title = "System Proxy"
        let proxySubmenu = NSMenu()
        for enabled in [true, false] {
            let item = NSMenuItem()
            item.title = enabled ? "Enabled" : "Disabled"
            item.state = appConfig.systemProxyEnabled == enabled ? .on : .off
            item.representedObject = enabled
            item.target = self
            item.action = #selector(setSystemProxy(_:))
            proxySubmenu.addItem(item)
        }
        systemProxyItem.submenu = proxySubmenu
        menu.addItem(systemProxyItem)

        let dnsItem = NSMenuItem()
        dnsItem.title = "System DNS"
        let dnsSubmenu = NSMenu()
        for enabled in [true, false] {
            let item = NSMenuItem()
            item.title = enabled ? "Enabled" : "Disabled"
            item.state = appConfig.dnsServerEnabled == enabled ? .on : .off
            item.representedObject = enabled
            item.target = self
            item.action = #selector(setSystemDNS(_:))
            dnsSubmenu.addItem(item)
        }
        dnsItem.submenu = dnsSubmenu
        menu.addItem(dnsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem()
        quitItem.title = "Quit Macxelio"
        quitItem.target = self
        quitItem.action = #selector(quitApp)
        quitItem.keyEquivalent = "q"
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)
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

    @objc func openMainWindow() {
        NSApp.setActivationPolicy(.regular)
        configureMainWindow()
        mainWindow()?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct MacxelioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var setupStep: SetupStep = .checking

    enum SetupStep {
        case checking
        case prepare
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
                    NotificationCenter.default.post(name: .openRules, object: nil)
                }) {
                    Label("Rules", systemImage: "list.bullet.rectangle")
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(setupStep != .ready)

                Button(action: {
                    NotificationCenter.default.post(name: .openHosts, object: nil)
                }) {
                    Label("Hosts", systemImage: "doc.plaintext")
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
                .disabled(setupStep != .ready)

                Button(action: {
                    NotificationCenter.default.post(name: .openEnvironments, object: nil)
                }) {
                    Label("Environments", systemImage: "square.grid.2x2")
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(setupStep != .ready)

                Button(action: {
                    NotificationCenter.default.post(name: .openConnections, object: nil)
                }) {
                    Label("Connections", systemImage: "network")
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
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
        Task.detached {
            let missing = Tools.missing()
            await MainActor.run {
                if missing.isEmpty {
                    setupStep = .ready
                    appDelegate.setupStatusBar()
                } else {
                    setupStep = .prepare
                }
            }
        }
    }
}

extension Notification.Name {
    static let openRules = Notification.Name("openRules")
    static let openHosts = Notification.Name("openHosts")
    static let openEnvironments = Notification.Name("openEnvironments")
    static let openConnections = Notification.Name("openConnections")
    static let openSettings = Notification.Name("openSettings")
    static let openHelp = Notification.Name("openHelp")
}
