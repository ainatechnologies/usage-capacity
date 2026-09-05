import XCTest
@testable import OpenUsage

final class CapacityProductTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    func snapshot(_ id: String, used: Double, limit: Double = 100, reset: Date? = nil) -> ProviderSnapshot {
        ProviderSnapshot(providerID: id, displayName: id, lines: [
            .progress(label: "Weekly", used: used, limit: limit, format: .percent, resetsAt: reset)
        ], refreshedAt: now)
    }
    func testBottleneckAcrossWindowsAndZeroQuota() {
        var value = snapshot("codex", used: 70)
        value.lines.append(.progress(label: "Session", used: 90, limit: 100, format: .percent))
        value.lines.append(.progress(label: "Spark", used: 100, limit: 100, format: .percent))
        let result = CapacityEngine.assess([value, snapshot("invalid", used: 0, limit: 0)], now: now)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].bottleneck.label, "Session")
        XCTAssertEqual(result[0].bottleneck.remaining, 0.1, accuracy: 0.00001)
    }
    func testStaleExcludedAndExpiredResetExcluded() {
        let values = CapacityEngine.assess([snapshot("codex", used: 5), snapshot("claude", used: 20),
            snapshot("expired", used: 0, reset: now.addingTimeInterval(-1))], errors: ["codex"], now: now)
        XCTAssertEqual(CapacityEngine.useNext(values)?.id, "claude")
        XCTAssertTrue(values.first { $0.id == "codex" }!.stale)
    }
    func testExpiringCapacityAndConserve() {
        let result = CapacityEngine.assess([snapshot("codex", used: 33, reset: now.addingTimeInterval(3600)),
                                           snapshot("claude", used: 95)], now: now)
        XCTAssertNotNil(result.first { $0.id == "codex" }?.expiring)
        XCTAssertTrue(result.first { $0.id == "claude" }!.conserve)
        XCTAssertEqual(CapacityEngine.useNext(result)?.id, "codex")
    }
    func testAPIAndTokensNeverBecomeQuota() {
        let value = ProviderSnapshot(providerID: "api", displayName: "API", lines: [
            .progress(label: "Total", used: 10, limit: 100, format: .dollars)
        ], refreshedAt: now)
        XCTAssertTrue(CapacityEngine.assess([value], now: now).isEmpty)
    }
    func testCalendarPeriodsExcludeNextMidnight() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let yesterday = AccountingPeriod.yesterday.interval(now: now, calendar: cal)
        XCTAssertEqual(yesterday.end, cal.startOfDay(for: now))
        XCTAssertEqual(yesterday.duration, 86400)
        XCTAssertEqual(AccountingPeriod.seven.interval(now: now, calendar: cal).start,
                       cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)))
        XCTAssertLessThan(AccountingPeriod.lifetime.interval(now: now).start,
                          AccountingPeriod.ninety.interval(now: now).start)
    }
    func testPricingExactModelAndCachedTokensNotDoubleCounted() {
        var event = CodexLogUsageScanner.Event(timestamp: now, model: "gpt-5.4", input: 100000,
            cached: 80000, output: 1000, reasoning: 500, total: 101000, recordedModel: "gpt-5.4")
        XCTAssertEqual(ReferencePricing.estimate(event)!, 0.085, accuracy: 0.000001)
        event.recordedModel = nil
        XCTAssertNil(ReferencePricing.estimate(event))
        event.recordedModel = "gpt-5.4-unknown"
        XCTAssertNil(ReferencePricing.estimate(event))
    }
    func testUnpricedObservedTokensRetained() {
        let entry = ObservedAccounting.Entry(id: "event", timestamp: now.addingTimeInterval(-1), model: "unknown",
            input: 90, cached: 50, output: 10, reasoning: 5, total: 100, equivalentUSD: nil, catalog: "fixture")
        let rows = ObservedAccounting.rows([entry], period: .lifetime, now: now)
        XCTAssertEqual(rows[0].tokens, 100)
        XCTAssertEqual(rows[0].unpricedTokens, 100)
        XCTAssertEqual(rows[0].equivalentUSD, 0)
    }

    @MainActor
    func testExplicitAccountHasIndependentStableID() throws {
        let name = "capacity-fixture-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = ProviderAccountsStore(defaults: defaults)
        let records = store.reconcile(with: [
            .init(family: "codex", identityKey: "fixture-work", label: "Work", sources: [
                .init(kind: .explicitHome, anchor: "/nonexistent/fixture", holdsDefaultSource: false)])
        ])
        XCTAssertTrue(records[0].id.hasPrefix("codex@"))
        XCTAssertEqual(ProviderAccountsStore(defaults: defaults).records, records)
        let providers = CodexProfileProvider.configured(defaults: defaults)
        XCTAssertEqual(providers.count, 1)
        XCTAssertTrue(providers[0].widgetDescriptors.allSatisfy { $0.providerID == records[0].id && !$0.isSpendTile })
    }

    @MainActor
    func testProfileDoesNotFallBackToDefaultLogin() async {
        let provider = CodexProfileProvider(id: "codex@fixture", name: "Fixture", home: "/nonexistent/capacity-fixture", identity: "fixture")
        let detected = await provider.hasLocalCredentials()
        XCTAssertFalse(detected)
        let snapshot = await provider.refresh()
        XCTAssertEqual(snapshot.providerID, "codex@fixture")
        XCTAssertTrue(snapshot.lines.contains { $0.label == MetricLine.errorBadgeLabel })
    }

    func testCopiedEventIdentityAndUnknownAttribution() {
        let event = CodexLogUsageScanner.Event(timestamp: now, model: "gpt-5", input: 100,
            cached: 0, output: 10, reasoning: 2, total: 110)
        XCTAssertEqual(ObservedAccounting.identity(event), ObservedAccounting.identity(event))
        XCTAssertNil(ReferencePricing.estimate(event), "upstream fallback must not become recorded attribution")
    }

    func testLedgerPersistsDeduplicatedUnpricedMetadata() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sessions = root.appendingPathComponent("sessions")
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let fixture = """
        {"type":"turn_context","payload":{"model":"fixture-model"}}
        {"timestamp":"2026-09-05T10:00:00Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":90,"cached_input_tokens":40,"output_tokens":10,"reasoning_output_tokens":5,"total_tokens":100}}}}
        """
        try fixture.write(to: sessions.appendingPathComponent("a.jsonl"), atomically: true, encoding: .utf8)
        try fixture.write(to: sessions.appendingPathComponent("copy.jsonl"), atomically: true, encoding: .utf8)
        let scanner = CodexLogUsageScanner(environment: CodexProfileEnvironment(home: root.path),
            incrementalScanner: IncrementalJSONLScanner<CodexLogUsageScanner.Event>())
        let file = root.appendingPathComponent("ledger.json")
        let ledger = ObservedAccounting(scanner: scanner, file: file)
        let first = try await ledger.refresh()
        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(first.first?.model, "fixture-model")
        XCTAssertEqual(first.first?.total, 100)
        XCTAssertNil(first.first?.equivalentUSD)
        try FileManager.default.removeItem(at: sessions)
        let reloaded = try await ObservedAccounting(scanner: scanner, file: file).refresh()
        XCTAssertEqual(reloaded.count, 1)
        XCTAssertEqual(reloaded.first?.id, first.first?.id)
        let permissions = try FileManager.default.attributesOfItem(atPath: file.path)[.posixPermissions] as? Int
        XCTAssertEqual(permissions, 0o600)
    }
}
