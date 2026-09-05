import XCTest
@testable import OpenUsage
final class TelemetrySinkTests: XCTestCase {
    func testNoTelemetryRegardlessOfInheritedPreference() {
        XCTAssertFalse(NoTelemetrySink.errorAutocaptureEnabled(optionalAnalyticsEnabled: true))
        XCTAssertFalse(NoTelemetrySink.errorAutocaptureEnabled(optionalAnalyticsEnabled: false))
    }
}
