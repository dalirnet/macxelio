import AppKit

/// Custom status bar menu item showing a left-aligned title with a status badge
/// floated to the trailing edge. Keeps its requested width minimal so it never
/// widens the menu; the badge only drifts right when other items make the menu wider.
final class MenuRow: NSView {
    private weak var target: AnyObject?
    private let action: Selector
    private let label = NSTextField(labelWithString: "")
    private let badgeView = NSImageView()

    private let leading: CGFloat = 14
    private let gap: CGFloat = 6
    private let trailing: CGFloat = 12
    private let rowHeight: CGFloat = 22

    init(title: String, badge: NSImage, target: AnyObject, action: Selector) {
        self.target = target
        self.action = action
        super.init(frame: .zero)
        autoresizingMask = [.width]

        label.font = NSFont.menuFont(ofSize: 0)
        label.stringValue = title
        addSubview(label)

        badgeView.image = badge
        badgeView.imageScaling = .scaleNone
        addSubview(badgeView)

        frame = NSRect(
            x: 0, y: 0,
            width: leading + label.fittingSize.width + gap + badge.size.width + trailing,
            height: rowHeight)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateBadge(_ badge: NSImage) {
        badgeView.image = badge
        needsLayout = true
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        let labelSize = label.fittingSize
        label.frame = NSRect(
            x: leading, y: (bounds.height - labelSize.height) / 2,
            width: labelSize.width, height: labelSize.height)
        let badgeSize = badgeView.image?.size ?? .zero
        badgeView.frame = NSRect(
            x: bounds.maxX - trailing - badgeSize.width,
            y: (bounds.height - badgeSize.height) / 2,
            width: badgeSize.width, height: badgeSize.height)
    }

    override func draw(_ dirtyRect: NSRect) {
        let highlighted = enclosingMenuItem?.isHighlighted == true
        if highlighted {
            NSColor.selectedContentBackgroundColor.setFill()
            bounds.fill()
        }
        label.textColor = highlighted ? .selectedMenuItemTextColor : .labelColor
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(
            NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self))
    }

    override func mouseEntered(with event: NSEvent) { needsDisplay = true }
    override func mouseExited(with event: NSEvent) { needsDisplay = true }

    override func mouseUp(with event: NSEvent) {
        guard let item = enclosingMenuItem else { return }
        item.menu?.cancelTracking()
        NSApp.sendAction(action, to: target, from: item)
    }
}
