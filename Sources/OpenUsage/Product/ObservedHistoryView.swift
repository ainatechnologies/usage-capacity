import SwiftUI

struct ObservedHistoryView: View {
    var onClose: () -> Void = {}
    @State private var period = AccountingPeriod.today
    @State private var entries: [ObservedAccounting.Entry] = []
    @State private var loading = false
    @State private var failure = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Codex · Observed history").font(.title2.weight(.semibold))
                Spacer()
                Button("Done", action: onClose).keyboardShortcut(.cancelAction)
            }
            Picker("Period", selection: $period) {
                ForEach(AccountingPeriod.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.menu)
            if loading { ProgressView("Reading local token metadata…") }
            if failure { Text("Local history could not be read or saved. Existing values remain visible.").foregroundStyle(.orange) }
            let rows = ObservedAccounting.rows(entries, period: period)
            if !loading || !entries.isEmpty {
                Text("\(rows.reduce(0) { $0 + $1.tokens }.formatted()) observed tokens").font(.headline)
            }
            if rows.contains(where: { $0.unpricedTokens < $0.tokens }) {
                Text("$\(rows.reduce(0) { $0 + $1.equivalentUSD }, specifier: "%.2f") API-equivalent · priced subset")
            } else if !rows.isEmpty {
                Text("API-equivalent unavailable for these models").foregroundStyle(.secondary)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(rows) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.model).font(.headline)
                            Text("\(row.tokens.formatted()) observed tokens")
                            if row.unpricedTokens < row.tokens {
                                Text("$\(row.equivalentUSD, specifier: "%.2f") API-equivalent · priced subset")
                            }
                            Text("Input \(row.input.formatted()) · cached \(row.cached.formatted()) · output \(row.output.formatted())")
                                .font(.caption).foregroundStyle(.secondary)
                            if row.unpricedTokens > 0 {
                                Text("\(row.unpricedTokens.formatted()) tokens unpriced").font(.caption).foregroundStyle(.orange)
                            }
                        }
                    }
                    if rows.isEmpty && !loading { Text("No observed events in this period.").foregroundStyle(.secondary) }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            Text("Local machine history, not subscription quota or actual spend. Estimates use frozen September 5, 2026 reference rates, not historical bills. Unknown models and unsupported pricing rules remain unpriced. Cached input is included in input; reasoning is included in output.")
                .font(.caption).foregroundStyle(.secondary)
            if let first = entries.first { Text("Observed coverage begins \(first.timestamp.formatted(date: .abbreviated, time: .omitted))").font(.caption) }
            Button("Refresh local history") { Task { await refresh() } }.disabled(loading)
        }.padding(24).frame(width: 660, height: 580)
        .task(id: period) { await refresh() }
    }
    private func refresh() async {
        let selected = period
        loading = true
        defer { if selected == period && !Task.isCancelled { loading = false } }
        do {
            let result = try await ObservedAccounting.shared.refresh(since: selected.interval(now: Date()).start)
            guard selected == period && !Task.isCancelled else { return }
            entries = result; failure = false
        } catch { if selected == period && !Task.isCancelled { failure = true } }
    }
}
