import SwiftUI

struct ViewLayout<
    HeaderLeft: View, HeaderRight: View, Content: View, FooterLeft: View, FooterRight: View
>: View {
    let headerLeft: HeaderLeft
    let headerRight: HeaderRight
    let content: Content
    let footerLeft: FooterLeft
    let footerRight: FooterRight

    init(
        @ViewBuilder headerLeft: () -> HeaderLeft,
        @ViewBuilder headerRight: () -> HeaderRight,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footerLeft: () -> FooterLeft,
        @ViewBuilder footerRight: () -> FooterRight
    ) {
        self.headerLeft = headerLeft()
        self.headerRight = headerRight()
        self.content = content()
        self.footerLeft = footerLeft()
        self.footerRight = footerRight()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                headerLeft
                Spacer()
                headerRight
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(height: 44)

            Divider()

            // Content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer
            HStack {
                footerLeft
                Spacer()
                footerRight
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(height: 44)
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
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .buttonStyle(.plain)
    }
}

struct HeaderTitle: View {
    let title: String
    var showFlame: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if showFlame {
                FlameIconView(isActive: false, size: 18)
                    .frame(width: 18, height: 18)
            }
            Text(title)
                .font(.system(size: 13, weight: .medium))
        }
    }
}
