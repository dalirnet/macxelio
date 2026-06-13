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
                                FormSection(category.rawValue, first: index == 0)

                                ForEach(environments) { environment in
                                    EnvironmentRow(
                                        environment: environment,
                                        isAvailable: service.isAvailable(environment),
                                        isOn: service.enabled.contains(environment.id),
                                        isChecking: service.checking.contains(environment.id),
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
    var isChecking: Bool = false
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(environment.name)
                .font(.system(size: 13))
                .foregroundColor(isAvailable ? .primary : .secondary)

            Spacer()

            if isChecking {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.8)
            } else {
                Toggle("", isOn: Binding(get: { isOn }, set: { onToggle($0) }))
                    .labelsHidden()
                    .disabled(!isAvailable)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
}
