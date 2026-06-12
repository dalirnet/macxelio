import SwiftUI

struct ViewLayout<HeaderLeft: View, HeaderRight: View, Content: View>: View {
    let headerLeft: HeaderLeft
    let headerRight: HeaderRight
    let content: Content

    init(
        @ViewBuilder headerLeft: () -> HeaderLeft,
        @ViewBuilder headerRight: () -> HeaderRight,
        @ViewBuilder content: () -> Content
    ) {
        self.headerLeft = headerLeft()
        self.headerRight = headerRight()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                headerLeft
                Spacer()
                headerRight
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(height: 48)

            Divider()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 320, height: 480)
    }
}

struct BackButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12))
                    .frame(width: 14, height: 14)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.cancelAction)
    }
}

struct HeaderButton: View {
    let icon: String
    var help: String = ""
    var size: CGFloat = 14
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

struct SaveButton: View {
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 15))
        }
        .buttonStyle(.plain)
        .help("Save")
        .disabled(disabled)
        .keyboardShortcut(.defaultAction)
    }
}

struct HeaderTitle: View {
    let title: String
    var showFlame: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if showFlame {
                FlameIconView(isActive: false, size: 16)
                    .frame(width: 16, height: 16)
            }
            Text(title)
                .font(.system(size: 13, weight: .semibold))
        }
    }
}
