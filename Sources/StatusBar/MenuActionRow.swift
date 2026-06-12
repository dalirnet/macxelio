import AppKit

final class MenuActionRow: NSView {
    private weak var target: AnyObject?
    private let action: Selector
    private let label = NSTextField(labelWithString: "")

    private let leading: CGFloat = 14
    private let trailing: CGFloat = 14
    private let rowHeight: CGFloat = 22
    private let highlightInset: CGFloat = 5
    private let highlightRadius: CGFloat = 5

    private var isHighlighted = false {
        didSet {
            label.textColor = isHighlighted ? .selectedMenuItemTextColor : .labelColor
            needsDisplay = true
        }
    }

    init(title: String, target: AnyObject, action: Selector) {
        self.target = target
        self.action = action
        super.init(frame: .zero)
        autoresizingMask = [.width]

        label.font = NSFont.menuFont(ofSize: 0)
        label.stringValue = title
        label.textColor = .labelColor
        addSubview(label)

        frame = NSRect(
            x: 0, y: 0, width: leading + label.fittingSize.width + trailing, height: rowHeight)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        let size = label.fittingSize
        label.frame = NSRect(
            x: leading, y: (bounds.height - size.height) / 2, width: size.width, height: size.height
        )
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(
            NSTrackingArea(
                rect: bounds, options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
                owner: self))
    }

    override func mouseEntered(with event: NSEvent) { isHighlighted = true }
    override func mouseExited(with event: NSEvent) { isHighlighted = false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard isHighlighted else { return }
        let rect = bounds.insetBy(dx: highlightInset, dy: 0)
        let path = NSBezierPath(
            roundedRect: rect, xRadius: highlightRadius, yRadius: highlightRadius)
        NSColor.selectedContentBackgroundColor.setFill()
        path.fill()
    }

    override func mouseUp(with event: NSEvent) {
        NSApp.sendAction(action, to: target, from: enclosingMenuItem)
    }
}
