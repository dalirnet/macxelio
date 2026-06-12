import AppKit

/// Factory for the small NSImages shown in the status bar menu.
enum MenuIcon {
    /// Outlined pill badge showing the current connectivity status / latency.
    static func latencyBadge(for status: ConnectivityChecker.Status) -> NSImage {
        let text: String
        switch status {
        case .ok: text = status.latencyText ?? ""
        case .checking: text = "CHECKING"
        case .error: text = "ERROR"
        case .unknown: text = "UNKNOWN"
        }

        let color = NSColor(status.color)
        let font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        let textSize = (text as NSString).size(withAttributes: attributes)

        let hPadding: CGFloat = 5
        let vPadding: CGFloat = 2
        let lineWidth: CGFloat = 1
        let width = ceil(textSize.width) + hPadding * 2
        let height = ceil(textSize.height) + vPadding * 2

        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        let rect = NSRect(x: 0, y: 0, width: width, height: height).insetBy(
            dx: lineWidth / 2, dy: lineWidth / 2)
        let path = NSBezierPath(roundedRect: rect, xRadius: height / 2, yRadius: height / 2)
        path.lineWidth = lineWidth
        color.setStroke()
        path.stroke()
        (text as NSString).draw(
            at: NSPoint(x: hPadding, y: vPadding), withAttributes: attributes)
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    /// Circle indicator for a boolean state: filled when on, outline when off.
    static func circle(filled: Bool) -> NSImage? {
        circle(symbol: filled ? "circle.fill" : "circle")
    }

    /// Circle indicator for the proxy mode: filled (global), half (rule), outline (direct).
    static func circle(for mode: AppConfig.ProxyMode) -> NSImage? {
        switch mode {
        case .global: return circle(symbol: "circle.fill")
        case .rule: return circle(symbol: "circle.lefthalf.filled")
        case .direct: return circle(symbol: "circle")
        }
    }

    private static func circle(symbol: String) -> NSImage? {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }
}
