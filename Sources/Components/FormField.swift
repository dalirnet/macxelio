import SwiftUI

private struct FieldBox: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
    }
}

extension View {
    fileprivate func fieldBox() -> some View { modifier(FieldBox()) }

    func rowTextField() -> some View {
        self
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .foregroundColor(.secondary)
    }

    func fullTextField() -> some View {
        self
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundColor(.secondary)
    }
}

struct FormSection: View {
    let title: String
    var first: Bool

    init(_ title: String, first: Bool = false) {
        self.title = title
        self.first = first
    }

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, first ? 0 : 14)
            .padding(.bottom, 4)
    }
}

struct FormFieldRow<Content: View>: View {
    let label: String?
    var error: String?
    let content: Content

    init(label: String? = nil, error: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.error = error
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if let label = label {
                    Text(label)
                        .font(.system(size: 13))
                }

                content
                    .frame(maxWidth: .infinity, alignment: label == nil ? .leading : .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)

            if let error = error, !error.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10))
                    Text(error)
                        .font(.system(size: 11))
                }
                .foregroundColor(.red)
            }
        }
    }
}

struct SelectBox<Value: Hashable>: View {
    let options: [(Value, String)]
    @Binding var selection: Value
    let label: String

    init(_ options: [(Value, String)], selection: Binding<Value>, label: String) {
        self.options = options
        self._selection = selection
        self.label = label
    }

    private var selectedLabel: String {
        options.first { $0.0 == selection }?.1 ?? ""
    }

    var body: some View {
        Menu {
            ForEach(options, id: \.0) { option in
                Button(action: { selection = option.0 }) {
                    if option.0 == selection {
                        Label(option.1, systemImage: "checkmark")
                    } else {
                        Text(option.1)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 13))

                Spacer()

                HStack(spacing: 4) {
                    Text(selectedLabel)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                }
                .foregroundColor(.secondary)
            }
            .fieldBox()
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }
}
