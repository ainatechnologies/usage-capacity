import Foundation

/// Compares general subscription windows only; balances and locally observed tokens are not quotas.
enum CapacityEngine {
    struct Window: Identifiable, Equatable {
        var id: String { label }
        let label: String
        let remaining: Double
        let reset: Date?
        let duration: TimeInterval?
    }
    struct Assessment: Identifiable {
        let id: String
        let name: String
        let windows: [Window]
        let stale: Bool
        let bottleneck: Window
        let expiring: Window?
        var conserve: Bool { bottleneck.remaining < 0.2 }
        var score: Double { bottleneck.remaining + (expiring == nil ? 0 : 0.15) }
    }

    static func assess(_ snapshots: [ProviderSnapshot], errors: Set<String> = [], now: Date = Date()) -> [Assessment] {
        snapshots.compactMap { snapshot in
            // Model-specific windows are intentionally not treated as a provider-wide bottleneck.
            let windows = snapshot.lines.compactMap { line -> Window? in
                guard case let .progress(label, used, limit, format, reset, duration, _) = line,
                      format == .percent, ["Session", "Weekly", "Total", "Monthly", "Premium Requests"].contains(label),
                      limit.isFinite, used.isFinite, limit > 0, used >= 0 else { return nil }
                return Window(label: label, remaining: max(0, min(1, 1 - used / limit)), reset: reset,
                              duration: duration.map { Double($0) / 1000 })
            }
            guard let bottleneck = windows.min(by: { $0.remaining < $1.remaining }) else { return nil }
            let stale = errors.contains(snapshot.providerID) || snapshot.errorCategory != nil
                || now.timeIntervalSince(snapshot.refreshedAt) > 15 * 60
                || windows.contains { $0.reset.map { $0 <= now } ?? false }
            let expiring = windows.filter {
                guard let reset = $0.reset else { return false }
                return $0.remaining >= 0.5 && reset > now && reset.timeIntervalSince(now) <= 6 * 3600
            }.min { ($0.reset ?? .distantFuture) < ($1.reset ?? .distantFuture) }
            return Assessment(id: snapshot.providerID, name: snapshot.displayName, windows: windows,
                              stale: stale, bottleneck: bottleneck, expiring: expiring)
        }.sorted { $0.id < $1.id }
    }

    static func useNext(_ assessments: [Assessment]) -> Assessment? {
        // No claim that equal percentages buy equal tokens, quality, or capability.
        assessments.filter { !$0.stale && !$0.conserve }.sorted {
            $0.score == $1.score ? $0.id < $1.id : $0.score > $1.score
        }.first
    }
}
