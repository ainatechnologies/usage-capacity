# Usage Capacity (working name)

An independent macOS 15+ fork of [OpenUsage](https://github.com/robinebers/openusage), built on its native Swift menu-bar and provider infrastructure. Not affiliated with or endorsed by OpenUsage.

Canonical repository: https://github.com/ainatechnologies/usage-capacity

## Build and run locally

Requires Xcode / Swift 6.2 or newer, macOS 15+, and an Apple Silicon Mac for the current local build.

```sh
bash script/build_product.sh
open "dist/Usage Capacity.app"
```

The bundle is ad-hoc signed for local development. Copy it to `~/Applications` for local installation. No upstream updater feed, signing identity, analytics SDK, or telemetry transport is configured.

```sh
CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-cache" OPENUSAGE_LIVE_CLAUDE=0 OPENUSAGE_CODEX_PARITY=0 OPENUSAGE_CLAUDE_PARITY=0 swift test --disable-sandbox -j 4
```

## Product layer

- Retains upstream status item, pinning, provider cards, refresh/caching, notifications, settings and provider contracts.
- Defaults to a pinned Codex weekly metric. Customize selects other windows/accounts and orders them. The native menu-bar strip updates from normalized live snapshots.
- Deterministic Use Next, general-window bottleneck, conserve and use-before-reset signals. Stale/expired data is excluded from recommendations.
- Existing upstream Claude organization cards; additional Codex CLI homes through Settings → Subscription stacking. Account identity checks prevent fallback to another login. Relaunch after adding a profile.
- Codex local observed-history accounting: Today, Yesterday, This Week, Last 7/30/90 Days, and all locally observed history. Recorded model breakdown, including unpriced tokens.
- API-equivalent comparison uses a frozen, dated reference catalog. It is not actual spend or a reconstruction of historical API bills. Current catalog coverage is deliberately limited; see [accounting](docs/product/accounting.md).
- Optional read-only localhost API, disabled by default; changes apply after relaunch.

Live Codex quota is separated from heavy local-history scanning. Machine-local tokens are never duplicated across stacked subscription accounts or claimed as official quota. No subscriptions or cancellation recommendations are inferred from token equivalents.

## Documentation

- [Migration and upstream comparison](docs/product/migration.md)
- [Provider contracts and limitations](docs/provider-contracts.md)
- [Product architecture](docs/product/architecture.md)
- [Accounting and pricing provenance](docs/product/accounting.md)
- [License review](docs/product/license-review.md)
- [Inherited architecture](docs/architecture.md), [menu bar](docs/menu-bar.md), [provider documentation](docs/README.md)

Inherited documentation describes upstream behavior; product deviations above and under `docs/product/` take precedence.

## License and upstream sync

MIT; preserve [LICENSE](LICENSE), [TRADEMARK.md](TRADEMARK.md), and packaged `Notices/`. The upstream source/module names remain for manageable merges; the app has its own bundle ID, working name, and SF Symbol icon.

Keep `upstream` pointing to robinebers/openusage. Merge upstream into a review branch, rerun fixture and native validation, check privacy and licensing changes, then integrate. Never replace this fork with a parallel implementation. Upstream release workflows are retained as disabled reference files under `docs/product/upstream-workflows`.
