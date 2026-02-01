import SwiftUI

enum AppScreen: Equatable {
    case main
    case settings
    case addConfig
    case editConfig(Config)
    case help
    case rules
    case addRule
    case editRule(Rule)
    case dns
    case addDNSServer
    case editDNSServer(DNSServer)
    case addDNSPolicy
    case editDNSPolicy(DNSPolicy)
    case connections
    case appUpdate
    case xrayUpdate
}

struct MainView: View {
    @ObservedObject var appConfig: AppConfig
    @ObservedObject var xrayCore: XrayCore

    @State private var currentScreen: AppScreen = .main

    var body: some View {
        Group {
            switch currentScreen {
            case .main:
                mainScreen
            case .settings:
                SettingsView(
                    appConfig: appConfig, xrayCore: xrayCore, onBack: { navigate(to: .main) })
            case .addConfig:
                ConfigFormView(appConfig: appConfig, onBack: { navigate(to: .main) })
            case .editConfig(let config):
                ConfigFormView(
                    appConfig: appConfig, editingConfig: config,
                    onBack: { navigate(to: .main) })
            case .help:
                HelpView(xrayCore: xrayCore, onBack: { navigate(to: .main) })
            case .rules:
                RulesView(
                    appConfig: appConfig,
                    onBack: { navigate(to: .main) },
                    onAdd: { navigate(to: .addRule) },
                    onEdit: { rule in navigate(to: .editRule(rule)) }
                )
            case .addRule:
                RuleFormView(appConfig: appConfig, onBack: { navigate(to: .rules) })
            case .editRule(let rule):
                RuleFormView(
                    appConfig: appConfig, editingRule: rule, onBack: { navigate(to: .rules) })
            case .dns:
                DNSView(
                    appConfig: appConfig,
                    onBack: { navigate(to: .main) },
                    onAddServer: { navigate(to: .addDNSServer) },
                    onEditServer: { server in navigate(to: .editDNSServer(server)) },
                    onAddPolicy: { navigate(to: .addDNSPolicy) },
                    onEditPolicy: { policy in navigate(to: .editDNSPolicy(policy)) }
                )
            case .addDNSServer:
                DNSServerFormView(appConfig: appConfig, onBack: { navigate(to: .dns) })
            case .editDNSServer(let server):
                DNSServerFormView(
                    appConfig: appConfig, editingServer: server, onBack: { navigate(to: .dns) })
            case .addDNSPolicy:
                DNSPolicyFormView(appConfig: appConfig, onBack: { navigate(to: .dns) })
            case .editDNSPolicy(let policy):
                DNSPolicyFormView(
                    appConfig: appConfig, editingPolicy: policy, onBack: { navigate(to: .dns) })
            case .connections:
                ConnectionsView(onBack: { navigate(to: .main) })
            case .appUpdate:
                AppUpdateView(onBack: { navigate(to: .main) })
            case .xrayUpdate:
                XrayUpdateView(onBack: { navigate(to: .main) })
            }
        }
        .animation(.easeInOut(duration: 0.15), value: currentScreen)
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            navigate(to: .settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: .addConfig)) { _ in
            navigate(to: .addConfig)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHelp)) { _ in
            navigate(to: .help)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAppUpdate)) { _ in
            navigate(to: .appUpdate)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openXrayUpdate)) { _ in
            navigate(to: .xrayUpdate)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openConnections)) { _ in
            navigate(to: .connections)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRules)) { _ in
            navigate(to: .rules)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDNS)) { _ in
            navigate(to: .dns)
        }
    }

    private func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.15)) {
            currentScreen = screen
        }
    }

    private var mainScreen: some View {
        ViewLayout(
            headerLeft: {
                HeaderTitle(title: "Macxelio", showFlame: true)
            },
            headerRight: {
                Button(action: { navigate(to: .addConfig) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            },
            content: {
                if appConfig.configs.isEmpty {
                    EmptyState("No configs yet", icon: "doc.text")
                } else {
                    StyledList(
                        appConfig.configs,
                        onDelete: { config in
                            appConfig.deleteConfig(config)
                        }
                    ) { config in
                        ConfigRow(
                            config: config,
                            isSelected: appConfig.selectedConfigId == config.id,
                            onSelect: {
                                if appConfig.selectedConfigId == config.id {
                                    appConfig.selectedConfigId = nil
                                } else {
                                    appConfig.selectedConfigId = config.id
                                }
                            },
                            onEdit: { navigate(to: .editConfig(config)) }
                        )
                    }
                }
            },
            footerLeft: {
                HStack(spacing: 8) {
                    ToggleChip(title: "DNS", isOn: $appConfig.dnsServerEnabled)
                    ToggleChip(title: "Proxy", isOn: $appConfig.systemProxyEnabled)
                }
            },
            footerRight: {
                Picker("", selection: $appConfig.proxyMode) {
                    ForEach(AppConfig.ProxyMode.allCases, id: \.self) { mode in
                        Text(mode.abbreviation).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
        )
    }
}
