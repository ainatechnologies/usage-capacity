# Observed accounting

The product ledger reuses OpenUsage's incremental Codex JSONL parser, cumulative-counter handling, inherited-child replay gate, and cache. It does not parse message content. It selects usage metadata and recorded model context. A new `recordedModel` field distinguishes known identifiers from upstream's historical `gpt-5` fallback. Cache schema 4 rebuilds the derived cache; original logs are untouched.

Deduplication hashes timestamp, recorded model, and all token counters. Like upstream, identical copied events count once. This is not a globally unique provider request ID; coincident identical legitimate events remain a possible undercount. Upstream's child replay heuristics and missing/truncated logs also bound accuracy. Local history is machine-scoped, not attributed to a paid account without evidence. Adding another account cannot multiply the ledger.

Input includes cached input. Non-cached input is `max(0, input - cached)`. Reasoning is a subset of output, not an additional charge. Observed totals remain included when pricing is unavailable. Missing recorded models are shown as Unknown, not guessed.

## Period semantics

Today/yesterday follow local calendar midnight. This Week follows the Mac calendar's week boundary. Last 7/30/90 Days include today and the preceding 6/29/89 calendar dates, through now; these are not rolling 168/720/2160-hour windows. Yesterday ends exclusively at today's midnight. LTD means all available local observed history, not account lifetime. Coverage begins at the first retained event; missing logs cannot be reconstructed.

## Dated comparison pricing

`ReferencePricing` is centralized and immutable for this catalog version. Current version: `openai-standard-reference-2026-09-05-v1`. It is a reference-price comparison, **not a historical-effective-rate catalog**. Existing per-event valuations and catalog IDs persist and do not change when the upstream dynamic pricing cache refreshes.

Verified September 5, 2026 against official model pages, USD per million tokens:

| Exact model | Input | Cached input | Output | Source |
|---|---:|---:|---:|---|
| gpt-5.3-codex | 1.75 | 0.175 | 14 | https://developers.openai.com/api/docs/models/gpt-5.3-codex |
| gpt-5.4 | 2.50 | 0.25 | 15 | https://developers.openai.com/api/docs/models/gpt-5.4 |
| gpt-5.5, gpt-5.5-2026-04-23 | 5 | 0.50 | 30 | https://developers.openai.com/api/docs/models/gpt-5.5 |

GPT-5.4/5.5 requests above 272K input use 2× input/cached input and 1.5× output. No regional surcharge is assumed. Fast/priority events and unknown aliases are unpriced. GPT-6 and GPT-5.6 are currently unpriced here because their separately priced cache-write buckets and other rules need reliable telemetry support. The UI explicitly reports the priced subset and unpriced tokens.

These numbers are API-equivalent estimates, not subscription spend, savings, profit, or provider bills. The inherited spend cards use upstream's dynamic catalog and are separate from this frozen ledger; they can differ. Full historical effective-rate provenance, actual subscription prices, billing periods, break-even, project/session attribution, and value multiples remain later work.

Ledger: `~/Library/Application Support/UsageCapacity/observed-ledger-v1.json`, atomic writes, owner-only permissions. It contains token metadata and catalog IDs only. No access tokens, prompts, responses, or cookies. Scans run on demand for the selected period in the detailed history view so live Codex quota cannot time out behind them. Today does not trigger an all-history pass. LTD explicitly requests the archival pass. The upstream parser pool is capped at two concurrent files. Closing the detailed window tears down its view and cancels its task. A cold archival pass can still take significant time on large histories.
