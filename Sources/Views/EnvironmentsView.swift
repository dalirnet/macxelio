import SwiftUI

struct EnvironmentsView: View {
    var onBack: () -> Void

    @StateObject private var service = EnvironmentService()

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Environments") { onBack() }
            },
            headerRight: { EmptyView() },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(
                            Array(ProxyEnvironment.Category.allCases.enumerated()), id: \.element
                        ) { index, category in
                            let environments = service.environments.filter {
                                $0.category == category
                            }
                            if !environments.isEmpty {
                                FormSection(
                                    category.rawValue, icon: category.icon, first: index == 0)

                                ForEach(environments) { environment in
                                    EnvironmentRow(
                                        environment: environment,
                                        isAvailable: service.isAvailable(environment),
                                        isOn: service.enabled.contains(environment.id),
                                        onToggle: { service.setEnabled(environment, $0) }
                                    )
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        )
        .onAppear { service.refresh() }
    }
}

struct EnvironmentRow: View {
    let environment: ProxyEnvironment
    let isAvailable: Bool
    let isOn: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        StyledRow {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(environment.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isAvailable ? .primary : .secondary)

                    Text(isAvailable ? environment.detail : "Not installed")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Toggle("", isOn: Binding(get: { isOn }, set: { onToggle($0) }))
                    .labelsHidden()
                    .disabled(!isAvailable)
            }
        }
    }
}
