import SwiftUI

struct StyledList<Data: RandomAccessCollection, RowContent: View>: View
where Data.Element: Identifiable {
    let data: Data
    let onEdit: ((Data.Element) -> Void)?
    let onDelete: ((Data.Element) -> Void)?
    let rowContent: (Data.Element) -> RowContent

    init(
        _ data: Data,
        onEdit: ((Data.Element) -> Void)? = nil,
        onDelete: ((Data.Element) -> Void)? = nil,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) {
        self.data = data
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.rowContent = rowContent
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(data) { item in
                    rowContent(item)
                        .contextMenu {
                            if let onEdit = onEdit {
                                Button("Edit") {
                                    onEdit(item)
                                }
                            }
                            if let onDelete = onDelete {
                                Button("Delete", role: .destructive) {
                                    onDelete(item)
                                }
                            }
                        }
                }
            }
            .padding(16)
        }
    }
}

struct StyledRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            .contentShape(Rectangle())
    }
}

struct StyledListRow<Left: View, Right: View>: View {
    let left: Left
    let right: Right

    init(
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self.left = left()
        self.right = right()
    }

    var body: some View {
        StyledRow {
            HStack(spacing: 10) {
                left

                Spacer()

                right
            }
        }
    }
}
