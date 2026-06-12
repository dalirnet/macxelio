import SwiftUI

struct RuleFormView: View {
    @ObservedObject var appConfig: AppConfig
    var editingRule: Rule?
    var onBack: () -> Void

    @State private var type: Rule.RuleType = .domain
    @State private var pattern = ""
    @State private var action: Rule.RuleAction = .direct

    var isEditing: Bool { editingRule != nil }

    private var patternError: String? {
        guard !pattern.isEmpty else { return nil }
        switch type {
        case .domain: return Validator.domainError(pattern)
        case .ip: return Validator.ipOrCIDRError(pattern)
        case .geoip, .geosite: return Validator.codeError(pattern)
        }
    }

    var isValid: Bool { !pattern.isEmpty && patternError == nil }

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: isEditing ? "Edit Rule" : "Add Rule") { onBack() }
            },
            headerRight: {
                SaveButton(disabled: !isValid) { saveRule() }
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        FormSection("Match", first: true)

                        SelectBox(
                            Rule.RuleType.allCases.map { ($0, $0.rawValue) },
                            selection: $type,
                            label: "Type"
                        )

                        FormFieldRow(label: "Pattern", error: patternError) {
                            TextField(patternPlaceholder, text: $pattern)
                                .rowTextField()
                        }

                        FormSection("Then")

                        SelectBox(
                            Rule.RuleAction.allCases.map { ($0, $0.rawValue) },
                            selection: $action,
                            label: "Action"
                        )
                    }
                    .padding(16)
                }
            }
        )
        .onAppear {
            if let rule = editingRule {
                type = rule.type
                pattern = rule.barePattern
                action = rule.action
            }
        }
    }

    private var patternPlaceholder: String {
        switch type {
        case .domain: return "*.google.com"
        case .ip: return "192.168.0.0/16"
        case .geoip: return "ir"
        case .geosite: return "category-ads"
        }
    }

    private func saveRule() {
        let rule = Rule(
            id: editingRule?.id ?? UUID(),
            type: type,
            pattern: pattern,
            action: action,
            createdAt: editingRule?.createdAt ?? Date()
        )

        if isEditing {
            appConfig.updateRule(rule)
        } else {
            appConfig.addRule(rule)
        }

        onBack()
    }
}
