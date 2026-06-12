import AppKit

enum MenuIcon {
    static func statusIcon(for status: ConnectivityChecker.Status) -> NSImage? {
        let config = NSImage.SymbolConfiguration(paletteColors: [NSColor(status.color)])
        let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        image?.isTemplate = false
        return image
    }

    static func circle(filled: Bool) -> NSImage? {
        symbol(filled ? "circle.fill" : "circle")
    }

    static func circle(for mode: AppConfig.ProxyMode) -> NSImage? {
        switch mode {
        case .global: return symbol("circle.fill")
        case .rule: return symbol("circle.lefthalf.filled")
        case .direct: return symbol("circle")
        }
    }

    static func symbol(_ name: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }
}
