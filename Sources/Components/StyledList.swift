import SwiftUI

/// A reusable styled list with consistent margins, swipe-to-delete, and row styling
struct StyledList<Data: RandomAccessCollection, RowContent: View>: View
where Data.Element: Identifiable {
    let data: Data
    let onDelete: ((Data.Element) -> Void)?
    let rowContent: (Data.Element) -> RowContent

    init(
        _ data: Data,
        onDelete: ((Data.Element) -> Void)? = nil,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) {
        self.data = data
        self.onDelete = onDelete
        self.rowContent = rowContent
    }

    var body: some View {
        List {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                rowContent(item)
                    .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
                    .padding(.top, index == 0 ? 8 : 0)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if let onDelete = onDelete {
                            Button(role: .destructive) {
                                onDelete(item)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .tint(.red)
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}

/// A styled row for use inside StyledList
struct StyledRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .contentShape(Rectangle())
    }
}

/// A styled list row with optional selection indicator and left/right content
struct StyledListRow<Left: View, Right: View>: View {
    let selectable: Bool
    let isSelected: Bool
    let left: Left
    let right: Right

    init(
        selectable: Bool = false,
        isSelected: Bool = false,
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self.selectable = selectable
        self.isSelected = isSelected
        self.left = left()
        self.right = right()
    }

    var body: some View {
        StyledRow {
            HStack(spacing: 8) {
                if selectable {
                    SelectionIndicator(isSelected: isSelected)
                }

                left

                Spacer()

                right
            }
        }
    }
}

extension StyledListRow where Right == EmptyView {
    init(
        selectable: Bool = false,
        isSelected: Bool = false,
        @ViewBuilder left: () -> Left
    ) {
        self.selectable = selectable
        self.isSelected = isSelected
        self.left = left()
        self.right = EmptyView()
    }
}
