import SwiftUI

struct CapacitySummaryView: View {
    let snapshots: [ProviderSnapshot]
    let errors: Set<String>

    var body: some View {
        let assessments = CapacityEngine.assess(snapshots, errors: errors)
        VStack(alignment: .leading, spacing: 8) {
            Text("AI CAPACITY").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            if let next = CapacityEngine.useNext(assessments) {
                Text("Use next · \(next.name)").font(.headline)
                Text("\(Int((next.bottleneck.remaining * 100).rounded()))% left in binding \(next.bottleneck.label.lowercased()) window")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("No fresh, unconstrained capacity to recommend").font(.subheadline)
            }
            ForEach(assessments.filter { $0.conserve || $0.expiring != nil || $0.stale }) { item in
                Text(attention(item)).font(.caption).foregroundStyle(item.stale ? .secondary : .primary)
            }
            Button("Codex observed history…") { ObservedHistoryWindow.shared.show() }
                .buttonStyle(.link).font(.caption)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private func attention(_ item: CapacityEngine.Assessment) -> String {
        if item.stale { return "\(item.name) · Stale — excluded from recommendations" }
        if item.conserve { return "\(item.name) · Conserve · \(Int(item.bottleneck.remaining * 100))% left" }
        if let window = item.expiring { return "\(item.name) \(window.label) · Use before reset · \(Int(window.remaining * 100))% left" }
        return item.name
    }
}
