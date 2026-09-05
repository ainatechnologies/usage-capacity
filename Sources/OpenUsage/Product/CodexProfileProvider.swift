import Foundation

/// Explicit Codex homes extend the upstream account registry; secrets stay in first-party auth files.
struct CodexProfileEnvironment: EnvironmentReading {
    let home: String
    func value(for name: String) -> String? { name == "CODEX_HOME" ? home : nil }
}
struct NoProfileKeychain: KeychainAccessing {
    func readGenericPassword(service: String) throws -> String? { nil }
    func writeGenericPassword(service: String, value: String) throws { throw CodexAuthError.notLoggedIn }
}

@MainActor
final class CodexProfileProvider: ProviderRuntime {
    let provider: Provider
    private let base: CodexProvider
    private let expectedIdentity: String
    private let environment: CodexProfileEnvironment
    init(id: String, name: String, home: String, identity: String) {
        self.environment = CodexProfileEnvironment(home: home)
        self.expectedIdentity = identity
        self.base = CodexProvider(authStore: CodexAuthStore(environment: environment, keychain: NoProfileKeychain()),
                                  includesLocalHistory: false)
        self.provider = Provider(id: id, displayName: String(name.prefix(32)), icon: .providerMark("codex"), links: base.provider.links)
    }
    var widgetDescriptors: [WidgetDescriptor] {
        base.widgetDescriptors.filter { !$0.isSpendTile && $0.historyResource == nil }.map {
            WidgetDescriptor(id: $0.id.replacingOccurrences(of: "codex.", with: provider.id + "."),
                providerID: provider.id, metricLabel: $0.metricLabel, sample: $0.sample,
                pinnable: $0.pinnable, isSpendTile: false, limitResources: $0.limitResources)
        }
    }
    private func matchesIdentity() -> Bool {
        let observer = DefaultAccountObserver(environment: environment, keychain: NoProfileKeychain())
        guard case .resolved(let identity, _, _) = observer.observeCodex() else { return false }
        return identity == expectedIdentity
    }
    func hasLocalCredentials() async -> Bool {
        guard matchesIdentity() else { return false }
        return await base.hasLocalCredentials()
    }
    func refresh() async -> ProviderSnapshot {
        guard matchesIdentity() else {
            return .error(provider: provider, message: "This Codex profile is signed out or its account changed. Re-add it in Settings.")
        }
        let value = await base.refresh()
        guard matchesIdentity() else { return .error(provider: provider, message: "Account changed during refresh. Re-add this profile.") }
        return ProviderSnapshot(providerID: provider.id, displayName: provider.displayName, plan: value.plan,
            lines: value.lines, refreshedAt: value.refreshedAt, warning: value.warning, errorCategory: value.errorCategory)
    }
    static func configured(defaults: UserDefaults) -> [ProviderRuntime] {
        ProviderAccountsStore(defaults: defaults).records.compactMap { record in
            guard record.family == "codex", !record.removedTombstone,
                  let source = record.sources.first(where: { $0.kind == .explicitHome }), let home = source.anchor else { return nil }
            return CodexProfileProvider(id: record.id, name: record.label ?? "Codex account", home: home, identity: record.identityKey)
        }
    }
}
