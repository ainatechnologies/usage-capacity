# Canonical Foundation Migration

Upstream: https://github.com/robinebers/openusage
Fork: https://github.com/ainatechnologies/usage-capacity
Baseline: 753e2fe4bc82a011567d16d8deb88176b58ed24e
Working name: Usage Capacity. This is an independent fork, not the official OpenUsage app.

## Reconciliation before implementation

**Keep from OpenUsage:** Swift 6 AppKit status item and key-capable panel; normalized ProviderRuntime → auth/client/mapper → ProviderSnapshot pipeline; WidgetDataStore cache/backoff; LayoutStore pins and customization; existing adapters and tests; incremental Codex parser including cumulative/fork deduplication; model pricing and model breakdown; account registry, Claude organization cards, account-stamped cache; local CLI and API serializer.

**Extend:** Account names/preferences and subscription metadata above stable provider-card IDs; conservative bottleneck/expiry/recommendation service over normalized quota lines; explicit API-equivalent labels; local history period aggregation over upstream daily/model history; opt-in API; isolated app storage and product identity.

**Port from prototype:** Only ideas and tested rules: exclude stale quota from recommendations; use the tightest applicable quota; prefer capable subscription capacity; prioritize substantial capacity about to reset; explicit task taxonomy and transparent reasons. Adapt to upstream models rather than import another model/provider/runtime.

**Discard:** Custom status item, popover, credential readers, provider adapters, SQLite history implementation, duplicated notification and API infrastructure. None is canonical.

**New modules:** Product identity/privacy policy; CapacityEngine; CapacityStore for quota observations and local account preferences; compact Use Next card; ObservedHistory report with calendar-correct periods and model rows; immutable pricing provenance ledger.

## Prior prototype preservation limitation

The user instructed this task to stop and scrap the prototype. It was stopped and moved to Trash before this strategy change. No commit existed at that point. On this migration, Finder displayed Trash as empty, so no original source repository could be recovered. There is no preserved prototype commit to report. The conversation retains its design and implementation evidence. Do not invent a commit or describe reconstructed code as the original archive. No second implementation is maintained.

## Safety deviations required before running

Upstream currently includes mandatory PostHog activity/crash reporting. This fork must remove the SDK/transport before launch to satisfy the user's no-telemetry requirement. Upstream's API starts automatically; this fork defaults it off. Keep cloud sync off and do not package upstream iCloud entitlements. Do not configure upstream Sparkle feeds. Change product name/icon and storage namespace; keep source target names to limit merge churn.

## First milestone sequence

1. Build baseline, inspect dependencies/licenses; retain license/trademark notices.
2. Apply identity/privacy isolation, build and run upstream shell.
3. Add read-only capacity layer and small dashboard entry point.
4. Extend existing daily/model accounting with requested report periods; clearly disclose coverage and pricing limitations.
5. Test quota/account isolation, stale data, expiry, recommendation decisions, history boundaries and menu-bar rendering; run live providers separately from fixtures.
6. Commit/push the canonical fork branch and document remaining work without overstating certification.

## Upstream sync

Keep upstream/main unchanged; product work lives on product/capacity-foundation. Fetch upstream and merge into an integration branch, run upstream and product tests, then review conflicts in the small integration seams. Never overwrite upstream history. Disable inherited release workflows until fork signing, feed and distribution configuration are intentionally established.

## Implemented reconciliation

No old prototype code was copied: the scrapped source was unavailable and no final prototype Git commit could be recovered. Its useful design requirements were re-expressed against upstream contracts. There is one canonical repository, not a maintained parallel prototype.

New modules: CapacityEngine/CapacitySummaryView, CodexProfileProvider/SubscriptionSettingsView, ObservedAccounting/ReferencePricing, ObservedHistoryView/ObservedHistoryWindow, ProductIdentity. Native status item, provider HTTP/auth code, refresh/cache isolation, settings/customization, notification and parser foundations remain upstream. The observed parser adds explicit recorded-model provenance; it does not replace cumulative/fork/subagent handling.

Runtime corrections: decouple live Codex quota from blocking history scans; package Sparkle with the correct relative framework search path; build/sign outside iCloud-managed directories if Finder metadata is restored; use a native detailed history window rather than a sheet on a nonactivating panel; label pinned windows even when only one metric is selected; preserve a labelled pending placeholder before the first successful fetch.
