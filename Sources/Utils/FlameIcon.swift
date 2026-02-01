import AppKit
import SwiftUI

struct FlameIconView: View {
    var isActive: Bool = false
    var size: CGFloat = 24

    var body: some View {
        Image(nsImage: FlameIcon.createMenuBarImage(size: size))
            .renderingMode(.template)
            .foregroundColor(isActive ? .orange : .secondary)
    }
}

struct FlameIcon {
    /// Creates the MDI fire icon path scaled to the given size
    static func createPath(size: CGFloat, offsetX: CGFloat = 0, offsetY: CGFloat = 0)
        -> NSBezierPath
    {
        let scale = size / 24.0
        let flamePath = NSBezierPath()

        // MDI fire path (flipped Y for macOS coordinates)
        flamePath.move(to: NSPoint(x: 17.66 * scale + offsetX, y: (24 - 11.2) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 16.89 * scale + offsetX, y: (24 - 10.38) * scale + offsetY),
            controlPoint1: NSPoint(x: 17.43 * scale + offsetX, y: (24 - 10.9) * scale + offsetY),
            controlPoint2: NSPoint(x: 17.15 * scale + offsetX, y: (24 - 10.64) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 14.82 * scale + offsetX, y: (24 - 8.72) * scale + offsetY),
            controlPoint1: NSPoint(x: 16.22 * scale + offsetX, y: (24 - 9.78) * scale + offsetY),
            controlPoint2: NSPoint(x: 15.46 * scale + offsetX, y: (24 - 9.35) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 13.95 * scale + offsetX, y: (24 - 3) * scale + offsetY),
            controlPoint1: NSPoint(x: 13.33 * scale + offsetX, y: (24 - 7.26) * scale + offsetY),
            controlPoint2: NSPoint(x: 13 * scale + offsetX, y: (24 - 4.85) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 11.46 * scale + offsetX, y: (24 - 4.32) * scale + offsetY),
            controlPoint1: NSPoint(x: 13 * scale + offsetX, y: (24 - 3.23) * scale + offsetY),
            controlPoint2: NSPoint(x: 12.17 * scale + offsetX, y: (24 - 3.75) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 9.07 * scale + offsetX, y: (24 - 13.22) * scale + offsetY),
            controlPoint1: NSPoint(x: 8.87 * scale + offsetX, y: (24 - 6.4) * scale + offsetY),
            controlPoint2: NSPoint(x: 7.85 * scale + offsetX, y: (24 - 10.07) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 9.15 * scale + offsetX, y: (24 - 13.55) * scale + offsetY),
            controlPoint1: NSPoint(x: 9.11 * scale + offsetX, y: (24 - 13.32) * scale + offsetY),
            controlPoint2: NSPoint(x: 9.15 * scale + offsetX, y: (24 - 13.42) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 8.8 * scale + offsetX, y: (24 - 14.05) * scale + offsetY),
            controlPoint1: NSPoint(x: 9.15 * scale + offsetX, y: (24 - 13.77) * scale + offsetY),
            controlPoint2: NSPoint(x: 9 * scale + offsetX, y: (24 - 13.97) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 8.14 * scale + offsetX, y: (24 - 13.93) * scale + offsetY),
            controlPoint1: NSPoint(x: 8.57 * scale + offsetX, y: (24 - 14.15) * scale + offsetY),
            controlPoint2: NSPoint(x: 8.33 * scale + offsetX, y: (24 - 14.09) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 8 * scale + offsetX, y: (24 - 13.76) * scale + offsetY),
            controlPoint1: NSPoint(x: 8.08 * scale + offsetX, y: (24 - 13.88) * scale + offsetY),
            controlPoint2: NSPoint(x: 8.04 * scale + offsetX, y: (24 - 13.83) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 7.45 * scale + offsetX, y: (24 - 8.64) * scale + offsetY),
            controlPoint1: NSPoint(x: 6.87 * scale + offsetX, y: (24 - 12.33) * scale + offsetY),
            controlPoint2: NSPoint(x: 6.69 * scale + offsetX, y: (24 - 10.28) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 5 * scale + offsetX, y: (24 - 14.47) * scale + offsetY),
            controlPoint1: NSPoint(x: 5.78 * scale + offsetX, y: (24 - 10) * scale + offsetY),
            controlPoint2: NSPoint(x: 4.87 * scale + offsetX, y: (24 - 12.3) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 5.29 * scale + offsetX, y: (24 - 15.97) * scale + offsetY),
            controlPoint1: NSPoint(x: 5.06 * scale + offsetX, y: (24 - 14.97) * scale + offsetY),
            controlPoint2: NSPoint(x: 5.12 * scale + offsetX, y: (24 - 15.47) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 6 * scale + offsetX, y: (24 - 17.7) * scale + offsetY),
            controlPoint1: NSPoint(x: 5.43 * scale + offsetX, y: (24 - 16.57) * scale + offsetY),
            controlPoint2: NSPoint(x: 5.7 * scale + offsetX, y: (24 - 17.17) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 10.96 * scale + offsetX, y: (24 - 20.92) * scale + offsetY),
            controlPoint1: NSPoint(x: 7.08 * scale + offsetX, y: (24 - 19.43) * scale + offsetY),
            controlPoint2: NSPoint(x: 8.95 * scale + offsetX, y: (24 - 20.67) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 17.03 * scale + offsetX, y: (24 - 19.32) * scale + offsetY),
            controlPoint1: NSPoint(x: 13.1 * scale + offsetX, y: (24 - 21.19) * scale + offsetY),
            controlPoint2: NSPoint(x: 15.39 * scale + offsetX, y: (24 - 20.8) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 18.56 * scale + offsetX, y: (24 - 12.72) * scale + offsetY),
            controlPoint1: NSPoint(x: 18.86 * scale + offsetX, y: (24 - 17.66) * scale + offsetY),
            controlPoint2: NSPoint(x: 19.5 * scale + offsetX, y: (24 - 15) * scale + offsetY))
        flamePath.line(to: NSPoint(x: 18.43 * scale + offsetX, y: (24 - 12.46) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 17.66 * scale + offsetX, y: (24 - 11.2) * scale + offsetY),
            controlPoint1: NSPoint(x: 18.22 * scale + offsetX, y: (24 - 12) * scale + offsetY),
            controlPoint2: NSPoint(x: 17.66 * scale + offsetX, y: (24 - 11.2) * scale + offsetY))

        // Inner flame
        flamePath.move(to: NSPoint(x: 14.5 * scale + offsetX, y: (24 - 17.5) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 13.4 * scale + offsetX, y: (24 - 18.1) * scale + offsetY),
            controlPoint1: NSPoint(x: 14.22 * scale + offsetX, y: (24 - 17.74) * scale + offsetY),
            controlPoint2: NSPoint(x: 13.76 * scale + offsetX, y: (24 - 18) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 10.5 * scale + offsetX, y: (24 - 17.28) * scale + offsetY),
            controlPoint1: NSPoint(x: 12.28 * scale + offsetX, y: (24 - 18.5) * scale + offsetY),
            controlPoint2: NSPoint(x: 11.16 * scale + offsetX, y: (24 - 17.94) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 12.61 * scale + offsetX, y: (24 - 15.23) * scale + offsetY),
            controlPoint1: NSPoint(x: 11.69 * scale + offsetX, y: (24 - 17) * scale + offsetY),
            controlPoint2: NSPoint(x: 12.4 * scale + offsetX, y: (24 - 16.12) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 12.33 * scale + offsetX, y: (24 - 13) * scale + offsetY),
            controlPoint1: NSPoint(x: 12.78 * scale + offsetX, y: (24 - 14.43) * scale + offsetY),
            controlPoint2: NSPoint(x: 12.46 * scale + offsetX, y: (24 - 13.77) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 12.5 * scale + offsetX, y: (24 - 10.94) * scale + offsetY),
            controlPoint1: NSPoint(x: 12.21 * scale + offsetX, y: (24 - 12.26) * scale + offsetY),
            controlPoint2: NSPoint(x: 12.23 * scale + offsetX, y: (24 - 11.63) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 13.13 * scale + offsetX, y: (24 - 12) * scale + offsetY),
            controlPoint1: NSPoint(x: 12.69 * scale + offsetX, y: (24 - 11.32) * scale + offsetY),
            controlPoint2: NSPoint(x: 12.89 * scale + offsetX, y: (24 - 11.7) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 15.37 * scale + offsetX, y: (24 - 14.8) * scale + offsetY),
            controlPoint1: NSPoint(x: 13.9 * scale + offsetX, y: (24 - 13) * scale + offsetY),
            controlPoint2: NSPoint(x: 15.11 * scale + offsetX, y: (24 - 13.44) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 15.43 * scale + offsetX, y: (24 - 15.23) * scale + offsetY),
            controlPoint1: NSPoint(x: 15.41 * scale + offsetX, y: (24 - 14.94) * scale + offsetY),
            controlPoint2: NSPoint(x: 15.43 * scale + offsetX, y: (24 - 15.08) * scale + offsetY))
        flamePath.curve(
            to: NSPoint(x: 14.5 * scale + offsetX, y: (24 - 17.5) * scale + offsetY),
            controlPoint1: NSPoint(x: 15.46 * scale + offsetX, y: (24 - 16.05) * scale + offsetY),
            controlPoint2: NSPoint(x: 15.1 * scale + offsetX, y: (24 - 16.95) * scale + offsetY))

        flamePath.windingRule = .evenOdd
        return flamePath
    }

    /// Creates a menu bar icon image with the flame symbol
    static func createMenuBarImage(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        let flamePath = createPath(size: size)
        NSColor.black.setFill()
        flamePath.fill()

        image.unlockFocus()

        return image
    }
}
