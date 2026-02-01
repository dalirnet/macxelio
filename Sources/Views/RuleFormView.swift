import SwiftUI

struct RuleFormView: View {
    @ObservedObject var appConfig: AppConfig
    var editingRule: Rule?
    var onBack: () -> Void

    @State private var type: Rule.RuleType = .domain
    @State private var pattern = ""
    @State private var action: Rule.RuleAction = .direct
    @State private var validationResult: String?

    var isEditing: Bool { editingRule != nil }
    var isValid: Bool { !pattern.isEmpty }

    var body: some View {
        ViewLayout(
            headerLeft: {
                BackButton(title: isEditing ? "Edit Rule" : "Add Rule") { onBack() }
            },
            headerRight: {
                Button("Save") { saveRule() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!isValid)
            },
            content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        FormField(label: "Type") {
                            Picker("", selection: $type) {
                                ForEach(Rule.RuleType.allCases, id: \.self) { t in
                                    Text(t.abbreviation).tag(t)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                        }

                        FormField(label: "Pattern") {
                            TextField(patternPlaceholder, text: $pattern)
                                .textFieldStyle(.roundedBorder)
                        }

                        FormField(label: "Action") {
                            Picker("", selection: $action) {
                                ForEach(Rule.RuleAction.allCases, id: \.self) { a in
                                    Text(a.abbreviation).tag(a)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                        }

                        if let result = validationResult {
                            Text(result)
                                .font(.caption)
                                .foregroundColor(result.contains("✓") ? .green : .orange)
                        }
                    }
                    .padding(12)
                }
            },
            footerLeft: { EmptyView() },
            footerRight: {
                Button("Validate") { validatePattern() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(pattern.isEmpty)
            }
        )
        .onAppear {
            if let rule = editingRule {
                type = rule.type
                pattern = rule.pattern
                action = rule.action
            }
        }
    }

    private var patternPlaceholder: String {
        switch type {
        case .domain: return "*.google.com"
        case .ip: return "192.168.0.0/16"
        case .geoip: return "geoip:ir"
        case .geosite: return "geosite:category-ads"
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

    private func validatePattern() {
        switch type {
        case .domain:
            validationResult =
                (pattern.contains(".") || pattern.hasPrefix("*"))
                ? "✓ Valid domain pattern" : "⚠ Should contain a dot or start with *"
        case .ip:
            validationResult =
                (pattern.contains("/") || pattern.contains("."))
                ? "✓ Valid IP pattern" : "⚠ Should be IP or CIDR notation"
        case .geoip:
            validationResult =
                pattern.hasPrefix("geoip:") ? "✓ Valid GeoIP pattern" : "⚠ Should start with geoip:"
        case .geosite:
            validationResult =
                pattern.hasPrefix("geosite:")
                ? "✓ Valid GeoSite pattern" : "⚠ Should start with geosite:"
        }
    }
}
