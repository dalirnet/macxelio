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

    fileprivate func fieldIcon() -> some View {
        self
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .frame(width: 16, height: 16)
    }

    func cardTextField() -> some View {
        HStack(spacing: 8) {
            self.textFieldStyle(.plain)

            Spacer(minLength: 0)
        }
        .fieldBox()
    }
}

struct FormField<Content: View>: View {
    let label: String
    var icon: String?
    var error: String?
    let content: Content

    init(
        label: String, icon: String? = nil, error: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.icon = icon
        self.error = error
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .frame(width: 14)
                }
                Text(label)
                    .font(.system(size: 12))
            }
            .foregroundColor(.secondary)

            content
                .frame(maxWidth: .infinity, alignment: .leading)

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

struct FormSection: View {
    let title: String
    var icon: String?
    var first: Bool

    init(_ title: String, icon: String? = nil, first: Bool = false) {
        self.title = title
        self.icon = icon
        self.first = first
    }

    var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
            }
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, first ? 0 : 14)
        .padding(.bottom, 4)
    }
}

struct PasswordField: View {
    let placeholder: String
    @Binding var text: String

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)

            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .fieldIcon()
            }
            .buttonStyle(.plain)
            .help(isVisible ? "Hide" : "Show")
        }
        .fieldBox()
    }
}

struct FormFieldRow<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13))

            Spacer()

            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct SelectBox<Value: Hashable>: View {
    let options: [(Value, String)]
    @Binding var selection: Value

    init(_ options: [(Value, String)], selection: Binding<Value>) {
        self.options = options
        self._selection = selection
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
                Text(selectedLabel)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .fieldIcon()
            }
            .fieldBox()
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }
}
