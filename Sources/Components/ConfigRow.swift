import SwiftUI

struct ConfigRow: View {
    let config: Config
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void

    var body: some View {
        StyledListRow(
            selectable: true,
            isSelected: isSelected,
            left: {
                Text(config.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
            },
            right: {
                if let ping = config.ping {
                    Text("\(ping)ms")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    Text("---")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        )
        .onTapGesture(count: 2) {
            onEdit()
        }
        .onTapGesture {
            onSelect()
        }
    }
}
