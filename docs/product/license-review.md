# License Review

Verified directly from LICENSE and TRADEMARK.md at upstream 753e2fe4bc82a011567d16d8deb88176b58ed24e on 2026-09-05.

OpenUsage source: MIT, copyright (c) 2026 Robin Ebers. Commercial use, modification, sublicensing and distribution are permitted. Preserve the copyright and complete permission/warranty notice in copies or substantial portions, including distributions. No source-disclosure obligation is imposed by MIT.

The MIT grant does not grant the OpenUsage trademark. The fork is named Usage Capacity, must use its own icon, and must clearly disclaim being official or endorsed. Preserve upstream LICENSE and TRADEMARK.md as attribution/legal records. Include notices in the app bundle.

Third-party runtime dependencies are reviewed from their resolved checkouts before distribution. No license assumption about bundled provider logos or third-party pricing datasets is inferred from the root MIT license. Upstream app-logo assets must not ship as the fork's identity. Provider names identify compatible services, not endorsement.

No modified binary is signed/notarized for public distribution in this milestone. A local ad-hoc signature is not public release certification.

## Resolved third-party notices

- KeyboardShortcuts 3.0.1: MIT; full resolved notice in `Notices/KeyboardShortcuts-MIT.txt`.
- Sparkle 2.9.6: complete license and bundled component notices in `Notices/Sparkle-and-third-parties.txt`.
- LiteLLM non-enterprise pricing data: MIT, Berri AI 2023. No enterprise-directory code is reused.
- models.dev pricing data: MIT, models.dev 2025.
- ccusage parser/pricing semantics referenced by upstream: MIT, ryoppippi 2025; notice retained conservatively.

The last three full notices were fetched from their official repository license paths on 2026-09-05 and are packaged under `Notices/`. No new runtime dependency was added. PostHog was removed entirely from Package.swift/Package.resolved and from packaged resource bundles. Its old SDK is not shipped.

Provider marks remain inherited compatibility identifiers, not this product's branding. Their independent trademark rights are not licensed by this fork. A public release still needs a complete asset provenance review; no public binary release is made here. The OpenUsage app mark is excluded from the app bundle.
