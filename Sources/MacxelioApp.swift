import Combine
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    var statusMenu: NSMenu?
    private var statusObserver: AnyCancellable?
    weak var statusMenuItem: NSMenuItem?
    var lastResolvedStatus: ConnectivityChecker.Status = .unknown

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
        refreshStatusMenuItem(status)

        let effective = status == .checking ? lastResolvedStatus : status
        if case .ok = effective {
            statusItem?.button?.alphaValue = 1.0
        } else {
            statusItem?.button?.alphaValue = 0.5
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

    @objc func openMainWindow() {
        NSApp.setActivationPolicy(.regular)
        configureMainWindow()
        mainWindow()?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hideMainWindow() {
        NSApp.setActivationPolicy(.accessory)
        mainWindow()?.orderOut(nil)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideMainWindow()
        return false
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

            CommandGroup(replacing: .appInfo) {
                Button("About Macxelio") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationIcon: FlameIcon.createImage(size: 256, color: .systemOrange),
                        .version: "",
                    ])
                }
            }

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
                ForEach(MenuPage.allCases, id: \.self) { page in
                    Button(action: {
                        NotificationCenter.default.post(name: page.notification, object: nil)
                    }) {
                        Label(page.title, systemImage: page.symbol)
                    }
                    .keyboardShortcut(
                        KeyEquivalent(Character(page.key)), modifiers: [.command, .shift]
                    )
                    .disabled(setupStep != .ready)
                }

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
                    appDelegate.hideMainWindow()
                } else {
                    setupStep = .prepare
                }
            }
        }
    }
}

extension Notification.Name {
    static let openMain = Notification.Name("openMain")
    static let openRules = Notification.Name("openRules")
    static let openHosts = Notification.Name("openHosts")
    static let openEnvironments = Notification.Name("openEnvironments")
    static let openConnections = Notification.Name("openConnections")
    static let openSettings = Notification.Name("openSettings")
    static let openHelp = Notification.Name("openHelp")
}
