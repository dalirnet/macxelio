import SwiftUI

/// Selection indicator circle
struct SelectionIndicator: View {
    let isSelected: Bool
    var activeColor: Color = .accentColor

    var body: some View {
        Image(systemName: isSelected ? "circle.fill" : "circle")
            .font(.system(size: 8))
            .frame(width: 12, height: 12)
            .foregroundColor(isSelected ? activeColor : .secondary)
    }
}

/// Small selection indicator for compact views
struct SelectionIndicatorSmall: View {
    let isSelected: Bool
    var activeColor: Color = .accentColor

    var body: some View {
        Image(systemName: isSelected ? "circle.fill" : "circle")
            .font(.system(size: 6))
            .frame(width: 8, height: 8)
            .foregroundColor(isSelected ? activeColor : .secondary)
    }
}
