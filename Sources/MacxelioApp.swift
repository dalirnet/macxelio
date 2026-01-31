import SwiftUI

@main
struct MacxelioApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(replacing: .help) {
                Button("Macxelio Help") {
                    NotificationCenter.default.post(name: .openHelp, object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button(action: {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }) {
                    Label("Settings", systemImage: "gearshape")
                }
                .keyboardShortcut(",", modifiers: .command)

                Button(action: {
                    NotificationCenter.default.post(name: .addServer, object: nil)
                }) {
                    Label("Add Server", systemImage: "plus.app")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
    static let addServer = Notification.Name("addServer")
    static let openHelp = Notification.Name("openHelp")
}
