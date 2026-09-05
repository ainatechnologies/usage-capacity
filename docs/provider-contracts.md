# Provider contracts

Pinned upstream: `753e2fe4bc82a011567d16d8deb88176b58ed24e`. The detailed source-backed contracts are retained in `docs/providers/`. Inclusion in the catalog is **not** proof that a provider works with credentials on this Mac.

| Provider | Authentication/data source | Available classes | Reliability / limits |
|---|---|---|---|
| Codex | CLI auth.json or upstream Keychain fallback; `https://chatgpt.com/backend-api/wham/usage` | Provider-reported session/weekly/model windows, resets, plan, credits; independent local token ledger | Private first-party contract; can change. Does not represent all consumer ChatGPT usage. Explicit extra CLI homes disable fallback and bind identity. |
| Claude | Claude Code OAuth / supported Claude Desktop organization credentials; upstream OAuth usage API | Provider-reported session/weekly/model windows, extra usage; locally derived history | Existing organization cards retained. Requires proper OAuth scope and current login. Not all accounts expose all windows. |
| Cursor | Cursor local auth; `api2.cursor.sh` dashboard RPCs plus upstream first-party fallback endpoints | Subscription budget windows, model pools, resets, on-demand amounts; usage history when exposed | Private changing contract. Provider-reported budget usage is not token quota. |
| Antigravity | Supported local tool auth; `cloudcode-pa.googleapis.com` / daily counterpart; Google OAuth refresh | Provider-reported model pools/windows | Partial Google support. Does not establish Google AI Pro consumer or Gemini CLI quota support. |
| Copilot | Supported local GitHub/Copilot credentials; `api.github.com/copilot_internal/user` | Quota/credits and resets when exposed | Account/plan dependent, private endpoint. Organization billing requires appropriate permission. |
| Grok | Grok CLI local OAuth; `cli-chat-proxy.grok.com/v1/settings` and billing | Coding-agent usage/credits | Does not claim generic Grok consumer subscription quota. |
| OpenRouter | User API key / supported environment credential; `/api/v1/credits`, `/api/v1/key` | Provider-reported API balance/spend | API accounting, not subscription quota. Manual key storage uses upstream Keychain. |
| Devin, Ollama, OpenCode, Z.ai | Retained upstream adapters; see individual provider docs | Adapter-specific quota/API/local usage | Present upstream, not certified live by this migration. |

No browser-cookie harvesting or website automation was added. Existing upstream provider contracts are used, not simulated cards. Google AI Pro, generic consumer ChatGPT, and generic consumer Grok limits remain unavailable unless a reliable specific contract exists. No OpenAI organization API billing adapter was added in this milestone.

Local tokens, API-equivalent costs, provider-reported balances, and subscription quota remain separate. The product recommendation engine only uses recognized general percentage windows; unknown or stale data is excluded. See `docs/product/accounting.md` for observed token and price limitations.
