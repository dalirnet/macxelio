import SwiftUI

enum AppScreen: Equatable {
    case main
    case addProxy
    case editProxy(Proxy)
    case rules
    case addRule
    case editRule(Rule)
    case hosts
    case addHost
    case editHost(Host)
    case environments
    case connections
    case settings
    case help
}

struct MainView: View {
    @ObservedObject var appConfig: AppConfig
    @ObservedObject var xrayCore: XrayCore

    @ObservedObject private var connectivity = ConnectivityChecker.shared
    @State private var currentScreen: AppScreen = .main

    var body: some View {
        Group {
            switch currentScreen {
            case .main:
                mainScreen
            case .addProxy:
                ProxyFormView(appConfig: appConfig, onBack: { navigate(to: .main) })
            case .editProxy(let proxy):
                ProxyFormView(
                    appConfig: appConfig, editingProxy: proxy,
                    onBack: { navigate(to: .main) })
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
            case .hosts:
                HostsView(
                    appConfig: appConfig,
                    onBack: { navigate(to: .main) },
                    onAdd: { navigate(to: .addHost) },
                    onEdit: { host in navigate(to: .editHost(host)) }
                )
            case .addHost:
                HostFormView(appConfig: appConfig, onBack: { navigate(to: .hosts) })
            case .editHost(let host):
                HostFormView(
                    appConfig: appConfig, editingHost: host,
                    onBack: { navigate(to: .hosts) })
            case .environments:
                EnvironmentsView(onBack: { navigate(to: .main) })
            case .connections:
                ConnectionsView(onBack: { navigate(to: .main) })
            case .settings:
                SettingsView(appConfig: appConfig, onBack: { navigate(to: .main) })
            case .help:
                HelpView(xrayCore: xrayCore, onBack: { navigate(to: .main) })
            }
        }
        .animation(.easeInOut(duration: 0.15), value: currentScreen)
        .onReceive(NotificationCenter.default.publisher(for: .openMain)) { _ in
            navigate(to: .main)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRules)) { _ in
            navigate(to: .rules)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHosts)) { _ in
            navigate(to: .hosts)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openEnvironments)) { _ in
            navigate(to: .environments)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openConnections)) { _ in
            navigate(to: .connections)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            navigate(to: .settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHelp)) { _ in
            navigate(to: .help)
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
                HeaderButton(icon: "plus", help: "Add Proxy") { navigate(to: .addProxy) }
            },
            content: {
                if appConfig.proxies.isEmpty {
                    EmptyState("No proxies yet", icon: "bolt.horizontal")
                } else {
                    StyledList(
                        appConfig.proxies,
                        onEdit: { proxy in navigate(to: .editProxy(proxy)) },
                        onDelete: { proxy in
                            appConfig.deleteProxy(proxy)
                        }
                    ) { proxy in
                        ProxyRow(
                            proxy: proxy,
                            isSelected: appConfig.selectedProxyId == proxy.id,
                            status: appConfig.selectedProxyId == proxy.id
                                ? connectivity.status : .unknown,
                            checkInterval: appConfig.selectedProxyId == proxy.id
                                ? connectivity.nextInterval : 0,
                            checkSequence: appConfig.selectedProxyId == proxy.id
                                ? connectivity.checkSequence : 0,
                            xrayRunning: xrayCore.isRunning,
                            isRestarting: xrayCore.isRestarting,
                            onSelect: {
                                guard appConfig.selectedProxyId != proxy.id else { return }
                                appConfig.selectedProxyId = proxy.id
                                connectivity.check()
                            },
                            onRestart: {
                                xrayCore.restart()
                                connectivity.check()
                            }
                        )
                    }
                }
            }
        )
    }
}

struct ProxyRow: View {
    let proxy: Proxy
    let isSelected: Bool
    let status: ConnectivityChecker.Status
    var checkInterval: Double = 0
    var checkSequence: Int = 0
    var xrayRunning: Bool = true
    var isRestarting: Bool = false
    let onSelect: () -> Void
    var onRestart: (() -> Void)? = nil

    @State private var spin = false

    var body: some View {
        HStack(spacing: 12) {
            StatusAvatar(
                status: status, checkInterval: checkInterval, checkSequence: checkSequence)

            VStack(alignment: .leading, spacing: 2) {
                Text(proxy.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("\(proxy.type.scheme.uppercased()) - \(proxy.address)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected, let onRestart {
                let showError = !xrayRunning && !isRestarting
                Button(action: onRestart) {
                    Image(
                        systemName: showError
                            ? "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
                            : "arrow.trianglehead.2.clockwise.rotate.90"
                    )
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(showError ? .red : .secondary)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(
                        isRestarting
                            ? .linear(duration: 0.7).repeatForever(autoreverses: false)
                            : .default,
                        value: spin
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRestarting)
                .help(xrayRunning ? "Restart Xray" : "Xray stopped — restart")
                .frame(width: 18, height: 18)
                .onChange(of: isRestarting) { spin = $0 }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? status.color.opacity(0.125) : Color.primary.opacity(0.05))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
