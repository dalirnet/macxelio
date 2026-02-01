import SwiftUI

struct ToggleChip: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 4) {
            SelectionIndicatorSmall(isSelected: isOn)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(isOn ? .primary : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isOn ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture {
            isOn.toggle()
        }
    }
}
