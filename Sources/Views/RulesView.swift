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
                HeaderButton(icon: "plus", help: "Add Rule") { onAdd() }
            },
            content: {
                if appConfig.rules.isEmpty {
                    EmptyState("No rules yet", icon: "list.bullet.rectangle")
                } else {
                    StyledList(
                        appConfig.rules,
                        onEdit: { rule in onEdit(rule) },
                        onDelete: { rule in
                            appConfig.deleteRule(rule)
                        }
                    ) { rule in
                        RuleRow(rule: rule)
                    }
                }
            }
        )
    }
}

struct RuleRow: View {
    let rule: Rule

    var body: some View {
        StyledListRow(
            left: {
                Text(rule.barePattern)
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
    }
}
