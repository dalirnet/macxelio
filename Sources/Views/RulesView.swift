import SwiftUI

struct RulesView: View {
    @ObservedObject var appConfig: AppConfig
    var onBack: () -> Void
    var onAdd: () -> Void
    var onEdit: (Rule) -> Void

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: "Rules") { onBack() }
            },
            headerRight: {
                Button(action: { onAdd() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            },
            content: {
                if appConfig.rules.isEmpty {
                    EmptyState("No rules yet", icon: "list.bullet.rectangle")
                } else {
                    StyledList(
                        appConfig.rules,
                        onDelete: { rule in
                            appConfig.deleteRule(rule)
                        }
                    ) { rule in
                        RuleRow(rule: rule, onEdit: { onEdit(rule) })
                    }
                }
            },
            footerLeft: {
                Text("\(appConfig.rules.count) rules")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            },
            footerRight: { EmptyView() }
        )
    }
}

struct RuleRow: View {
    let rule: Rule
    let onEdit: () -> Void

    var body: some View {
        StyledListRow(
            left: {
                Text(rule.pattern)
                    .font(.system(size: 13, design: .monospaced))
                    .lineLimit(1)
            },
            right: {
                HStack(spacing: 6) {
                    Badge(rule.type.rawValue)
                    Badge(rule.action.rawValue)
                }
            }
        )
        .onTapGesture {
            onEdit()
        }
    }
}
