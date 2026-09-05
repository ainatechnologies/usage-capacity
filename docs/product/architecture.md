# Product architecture and deviations

Baseline: OpenUsage `753e2fe4bc82a011567d16d8deb88176b58ed24e`. See inherited `docs/architecture.md` for the foundation.

The product layer lives in `Sources/OpenUsage/Product`. `CapacityEngine` consumes existing `ProviderSnapshot`/`MetricLine` values; the dashboard adds one summary above upstream provider cards. `CodexProfileProvider` wraps upstream Codex runtime for explicit homes and remaps stable descriptor/card IDs. `ProviderAccountsStore` gains one source kind, `explicitHome`; no parallel account registry is introduced. An account's provider-reported plan identifies its current subscription, with independent windows carried by existing metric lines. Multiple simultaneous products on one account still need a richer subscription record.

Configured profile credentials stay in the selected first-party CLI home. Generic Keychain fallback is disabled for those profiles. Identity is checked before and after refresh. Duplicate provider identities are rejected; changed/signed-out profiles become errors and retain stale cached data. Additional profiles expose quota only, avoiding ambiguous duplication of local telemetry. Changes currently require relaunch.

Capacity uses only recognized general percentage windows. The smallest remaining fraction is the bottleneck. Model-specific pools do not constrain a general recommendation. Values with invalid/zero denominators, stale snapshots, expired reset times, and failures cannot produce a fresh recommendation. Conserve is below 20%; use-before-reset is at least 50% remaining and a reset within six hours. Recommendation ranks fresh unconstrained candidates by remaining fraction plus a small expiry preference, with stable tie-breaking. It does not claim equal quota percentages buy equal tokens or model quality. Capability-aware policies and historical burn velocity are not yet implemented.

The existing status-item observer, image renderer, stable pin IDs, menu-bar styles, and no-flicker apply gate remain. Product default pin is Codex Weekly. OpenUsage's label/style controls remain authoritative. The SF Symbol working icon replaces the OpenUsage logo.

Codex live fetch bypasses upstream's blocking local spend scans after runtime testing showed cold scans could exceed its 120-second refresh timeout. The parser is retained and exposed through the detailed observed-history window, scoped to the selected calendar period. No separate provider HTTP implementation was introduced.

Privacy deviations: PostHog SDK/package/transport removed; `NoTelemetrySink` preserves upstream seams but sends nothing. Local API is disabled unless explicitly configured and binds only to loopback. App bundle ID, support/log/cache paths and name are isolated from upstream. iCloud and upstream updater feed/signing entitlements are not packaged. Inherited CI/release workflows are disabled reference files until fork-specific release configuration exists.

Merge upstream into a temporary branch. Preserve these explicit seams, inspect changed auth/network/license behavior, run fixtures with live tests disabled, then build/sign/run the product bundle and exercise menu bar, refresh, history, profile identity, and idle behavior. Never blindly enable inherited telemetry, distribution workflows, updater feed, or branding.
