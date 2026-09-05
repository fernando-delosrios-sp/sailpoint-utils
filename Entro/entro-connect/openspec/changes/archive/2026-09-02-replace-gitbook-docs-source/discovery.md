## Scope

Replace the GitBook markdown-catalog source used by Stage 1 documentation ingest with the more complete password-protected `https://docs.entro.security/` site; include operator-exported session-cookie auth, authenticated discovery, crawling, durable markdown output, and failure reporting, but exclude documentation distillation, skill changes, CLI automation, browser-driven login, and any committed credential material.

## Language

**Protected documentation source** (`draft`):
The Entro documentation site at `https://docs.entro.security/`, whose pages require a GitBook visitor-auth session before ingest can discover or fetch them.
_Avoid_: public GitBook catalog, key-free GitBook source, HTTP Basic source

**Crawler credential file** (`draft`):
A local, gitignored `.env` file read by the ingest process at runtime. For this change it holds `ENTRO_DOCS_COOKIE` (the `Cookie` request header from an already-authenticated browser session). Values are never read into agent context, copied into generated output, logged, or committed.
_Avoid_: checked-in credentials, agent-managed secrets, username and password in ingest, command-line cookie arguments

**Operator session cookie** (`draft`):
The `Cookie` header value the browser sends to `https://docs.entro.security/` after the operator completes visitor login. Ingest injects that string as a request header; it does not complete Descope or GitBook login itself.
_Avoid_: HTTP Basic, Authorization header, browser automation

The canonical terms Documentation ingest and Documentation tree remain unchanged.

## Decisions

Context → The current ingest depends on GitBook's public `llms.txt` and per-page markdown endpoints. The replacement site is more complete and is gated by GitBook visitor auth via Descope OIDC, not HTTP Basic.

Authentication boundary → The operator selected a local ignored credential file. After a live probe, username/password cannot be sent as Basic auth. The operator logs in once in a browser; ingest reads `ENTRO_DOCS_COOKIE` and sends it as the `Cookie` header. README and CLI errors must state those steps; planning and implementation must not inspect cookie values.

Source strategy → Treat `https://docs.entro.security/` as the authoritative integration-documentation source. Do not fall back to `entro.gitbook.io`.

Output boundary → Preserve `documentation/` as the durable ingest root. Replace source-derived content only after a successful crawl has produced a valid non-empty result.

Stage intent → This is Stage 1 documentation extraction only. It does not change Integration prep, Connection details, or `entro-connect` behavior.

## Open questions

Resolved: credential transport is gitignored `.env`; injection is `ENTRO_DOCS_COOKIE` as a `Cookie` header. Cookie names are not hardcoded; the operator copies the full header from a successful docs-site request after login.

Deferred: retirement of historical `crawl_docs.py` and root crawl blobs; distillation of newly discovered pages; crawler-driven Descope/OIDC login.

## Scenarios discussed

- Missing or empty `ENTRO_DOCS_COOKIE` fails before any network crawl, prints the operator cookie steps, and does not modify the current documentation tree.
- A cookie that still redirects to Descope or GitBook visitor-auth fails closed with the same operator steps and does not fall back to the public GitBook catalog.
- A successful authenticated start-page fetch discovers same-origin documentation links while excluding logout, account, and unrelated external URLs.
- Duplicate links, fragments, and query variants resolve to one page.
- A single page failure is reported while remaining pages are attempted; the run remains unsuccessful.
- Cookie values and `Cookie` / `Authorization` headers never appear in logs, markdown, generated indexes, fixtures, or errors.
- An empty or structurally invalid crawl cannot replace the existing committed documentation tree.
