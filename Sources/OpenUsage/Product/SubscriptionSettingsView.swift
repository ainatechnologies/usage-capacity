import AppKit
import SwiftUI

struct SubscriptionSettingsView: View {
    @State private var label = "Work Codex"
    @State private var message: String?
    @AppStorage("usagecapacity.localAPIEnabled") private var localAPI = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subscription stacking").font(.headline)
            Text("Existing Claude organizations are detected by upstream. Add another Codex account using its separate, already authenticated CLI home.")
                .font(.caption).foregroundStyle(.secondary)
            TextField("Short account label", text: $label)
            Button("Choose Codex home…") { chooseHome() }
            if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
            Toggle("Read-only localhost API", isOn: $localAPI)
            Text("API and account changes apply after relaunch. API binds to 127.0.0.1:6736; other local processes can read normalized usage.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(12)
    }
    private func chooseHome() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.prompt = "Add account"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let home = url.resolvingSymlinksInPath().standardizedFileURL.path
        let observer = DefaultAccountObserver(environment: CodexProfileEnvironment(home: home), keychain: NoProfileKeychain())
        guard case .resolved(let identity, _, _) = observer.observeCodex() else {
            message = "No identifiable Codex subscription login found in that directory."; return
        }
        let store = ProviderAccountsStore()
        guard !store.records.contains(where: { $0.family == "codex" && $0.identityKey == identity }) else {
            message = "This account is already tracked; adding its quota twice would inflate capacity."; return
        }
        store.reconcile(with: [.init(family: "codex", identityKey: identity,
            label: label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Codex account" : String(label.prefix(32)),
            sources: [.init(kind: .explicitHome, anchor: home, holdsDefaultSource: false)])])
        message = "Account added. Relaunch Usage Capacity to display and pin its quota windows. Local tokens remain machine-scoped."
    }
}
