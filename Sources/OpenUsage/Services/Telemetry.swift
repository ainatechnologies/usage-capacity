import Foundation

/// Compatibility seam for upstream tests. The product uses a no-op sink with no network code.
@MainActor
protocol TelemetrySink: AnyObject {
    func capture(_ event: String, _ properties: [String: Any])
    /// Retained upstream preference seam; no reporting is enabled by it.
    func setOptionalAnalyticsEnabled(_ enabled: Bool)
    func flush()
}

// Product privacy boundary: no SDK, network transport, crash capture, or environment override.
@MainActor
final class NoTelemetrySink: TelemetrySink {
    nonisolated static func errorAutocaptureEnabled(optionalAnalyticsEnabled _: Bool) -> Bool { false }
    init(enabled: Bool, token: String = "", host: String = "") {}
    func capture(_ event: String, _ properties: [String: Any]) {}
    func setOptionalAnalyticsEnabled(_ enabled: Bool) {}
    func flush() {}
}
