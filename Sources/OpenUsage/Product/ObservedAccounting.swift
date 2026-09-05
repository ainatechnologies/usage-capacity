import CryptoKit
import Foundation

enum AccountingPeriod: String, CaseIterable, Identifiable {
    case today = "Today", yesterday = "Yesterday", week = "This Week"
    case seven = "Last 7 Days", thirty = "Last 30 Days", ninety = "Last 90 Days", lifetime = "LTD / Local history"
    var id: String { rawValue }
    func interval(now: Date, calendar: Calendar = .current) -> DateInterval {
        let today = calendar.startOfDay(for: now)
        func days(_ value: Int) -> Date { calendar.date(byAdding: .day, value: value, to: today)! }
        switch self {
        case .today: return DateInterval(start: today, end: now)
        case .yesterday: return DateInterval(start: days(-1), end: today)
        case .week: return DateInterval(start: calendar.dateInterval(of: .weekOfYear, for: now)!.start, end: now)
        case .seven: return DateInterval(start: days(-6), end: now)
        case .thirty: return DateInterval(start: days(-29), end: now)
        case .ninety: return DateInterval(start: days(-89), end: now)
        case .lifetime: return DateInterval(start: .distantPast, end: now)
        }
    }
}

/// Persisted costs are immutable observations of a dated catalog, not reconstructed historical bills.
/// A catalog update never rewrites a previously recorded valuation.
actor ObservedAccounting {
    static let shared = ObservedAccounting()
    struct Entry: Codable, Sendable {
        let id: String
        let timestamp: Date
        let model: String
        let input: Int
        let cached: Int
        let output: Int
        let reasoning: Int
        let total: Int
        let equivalentUSD: Double?
        let catalog: String
    }
    struct ModelRow: Identifiable, Sendable {
        var id: String { model }
        let model: String
        var tokens = 0
        var input = 0
        var cached = 0
        var output = 0
        var reasoning = 0
        var equivalentUSD: Double = 0
        var unpricedTokens = 0
    }
    private let scanner: CodexLogUsageScanner
    private let file: URL
    private var entries: [String: Entry]?
    init(scanner: CodexLogUsageScanner = CodexLogUsageScanner(), file: URL? = nil) {
        self.scanner = scanner
        self.file = file ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("UsageCapacity/observed-ledger-v1.json")
    }
    func refresh(since: Date = .distantPast) async throws -> [Entry] {
        if entries == nil {
            if FileManager.default.fileExists(atPath: file.path) {
                let decoded = try JSONDecoder().decode([Entry].self, from: Data(contentsOf: file))
                entries = Dictionary(decoded.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            } else { entries = [:] }
        }
        guard let events = await scanner.observedEvents(since: since), !Task.isCancelled else { return Array(entries!.values) }
        for event in events {
            let id = Self.identity(event)
            guard entries![id] == nil else { continue }
            let model = event.recordedModel ?? "Unknown (not recorded)"
            entries![id] = Entry(id: id, timestamp: event.timestamp, model: model, input: event.input,
                cached: event.cached, output: event.output, reasoning: event.reasoning, total: event.total,
                equivalentUSD: ReferencePricing.estimate(event), catalog: ReferencePricing.version)
        }
        let result = Array(entries!.values).sorted { $0.timestamp < $1.timestamp }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true,
                                               attributes: [.posixPermissions: 0o700])
        try JSONEncoder().encode(result).write(to: file, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        return result
    }
    static func identity(_ event: CodexLogUsageScanner.Event) -> String {
        let raw = "\(event.timestamp.timeIntervalSince1970)|\(event.recordedModel ?? "?")|\(event.input)|\(event.cached)|\(event.output)|\(event.reasoning)|\(event.total)"
        return SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    static func rows(_ entries: [Entry], period: AccountingPeriod, now: Date = Date(), calendar: Calendar = .current) -> [ModelRow] {
        let interval = period.interval(now: now, calendar: calendar)
        var rows: [String: ModelRow] = [:]
        for entry in entries where entry.timestamp >= interval.start && entry.timestamp < interval.end {
            var row = rows[entry.model] ?? ModelRow(model: entry.model)
            row.tokens += entry.total; row.input += entry.input; row.cached += entry.cached
            row.output += entry.output; row.reasoning += entry.reasoning
            if let cost = entry.equivalentUSD { row.equivalentUSD += cost } else { row.unpricedTokens += entry.total }
            rows[entry.model] = row
        }
        return rows.values.sorted { $0.tokens == $1.tokens ? $0.model < $1.model : $0.tokens > $1.tokens }
    }
}

/// Exact identifiers only. This dated comparison catalog is not a claim of historical effective rates.
/// Unknown cache-write splits and priority pricing remain unpriced for newer models.
enum ReferencePricing {
    static let version = "openai-standard-reference-2026-09-05-v1"
    static let source = "https://developers.openai.com/api/docs/models/gpt-5.4"
    static func estimate(_ event: CodexLogUsageScanner.Event) -> Double? {
        guard let model = event.recordedModel, !event.isFast else { return nil }
        let rates: (Double, Double, Double)
        switch model {
        case "gpt-5.5", "gpt-5.5-2026-04-23": rates = (5, 0.5, 30)
        case "gpt-5.4": rates = (2.5, 0.25, 15)
        case "gpt-5.3-codex": rates = (1.75, 0.175, 14)
        default: return nil
        }
        let long = model != "gpt-5.3-codex" && event.input > 272_000
        return (Double(max(0, event.input - event.cached)) * rates.0 * (long ? 2 : 1)
            + Double(event.cached) * rates.1 * (long ? 2 : 1)
            + Double(event.output) * rates.2 * (long ? 1.5 : 1)) / 1_000_000
    }
}
