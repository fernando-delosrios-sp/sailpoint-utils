## Context

`ingest_docs.py` currently parses a public GitBook markdown catalog and fetches each linked `.md` page directly into `documentation/`. The replacement source, `https://docs.entro.security/`, is more complete and does not expose that `llms.txt` contract. A live unauthenticated GET redirects into GitBook visitor auth via Descope OIDC (`api.descope.com`, `sso_app_id=Gitbooks`). Username and password are entered in that browser flow; they cannot be injected as HTTP Basic.

The operator owns the session in the browser and the cookie string in the existing gitignored `.env`. Neither planning nor implementation reads those values into agent context.

## Goals / Non-Goals

**Goals:**

- Tell the operator, in README and in CLI failures, how to log in once and export a session cookie.
- Authenticate fetches with `ENTRO_DOCS_COOKIE` sent as the `Cookie` header.
- Discover and normalize same-origin documentation pages without relying on the public GitBook catalog.
- Convert fetched pages to durable markdown under the existing `documentation/` root.
- Prevent missing cookies, rejected sessions, empty discovery, or partial fetches from replacing the last valid tree.
- Preserve useful failure reporting without exposing cookie or authorization data.

**Non-Goals:**

- Driving Descope, SSO, MFA, or CAPTCHA in the crawler.
- HTTP Basic or command-line cookie arguments.
- GitBook catalog fallback.
- Changes to Integration prep, Connection details, `entro-connect`, or the Entro API snapshot command.
- Historical crawler cleanup or content distillation.

## Decisions

### D1: Operator browser login, then Cookie header
- **Choice**: ingest never logs in. The operator authenticates in a browser until documentation pages are visible, copies the `Cookie` request header for `https://docs.entro.security/`, stores it as `ENTRO_DOCS_COOKIE` in `.env`, and ingest sends that string on every fetch. Do not hardcode GitBook cookie names; the full header covers whatever the site set after login.
- **Reason**: the live site is visitor-auth OIDC, not Basic. Replaying the browser's `Cookie` header is the smallest non-interactive injection that matches how GitBook already authorizes the operator.
- **Considered alternatives**: HTTP Basic (rejected after the live redirect to Descope); crawler-driven browser login (out of scope); a named `gitbook-visitor-token` only (that cookie is GitBook's adaptive-content product-login pattern, not this site's OIDC session).

### D2: Parse only `ENTRO_DOCS_COOKIE` from `.env`
- **Choice**: read that one documented variable from the repo-local ignored file or process environment, without printing the value, dumping the file, or overwriting already-set process values.
- **Reason**: honors the operator-selected credential file with a narrow secret surface.
- **Considered alternatives**: dotenv dependency or shell-sourcing `.env`. Rejected because the format needed is small and shell sourcing executes arbitrary content.

### D3: Operator instructions are part of the interface
- **Choice**: README, `ingest_docs.py --help`, and missing/rejected-session stderr all carry the same numbered steps: open the site, complete login until docs are visible, copy the `Cookie` header from a successful docs-host request (DevTools Network), set `ENTRO_DOCS_COOKIE` in `.env`, rerun ingest. Failures that land on Descope or GitBook visitor-auth use those steps, not a generic “auth failed”.
- **Reason**: cookie export is easy to get wrong; the process must teach the operator without the agent ever seeing the cookie.
- **Considered alternatives**: README-only, or pointing at cookie names without the Network-header copy path. Rejected because HttpOnly cookies and multiple names make a full `Cookie` header the reliable paste.

### D4: Treat login redirects as a rejected session
- **Choice**: if the start-page response redirects off `docs.entro.security`, or the body is the Descope/GitBook login challenge rather than documentation, fail closed. Do not follow that login as a crawl target.
- **Reason**: a 200 login page must not be published as documentation or mistaken for success.
- **Considered alternatives**: following the OIDC redirect and scraping the login form. Rejected; that is crawler-driven auth.

### D5: Discover a same-origin page graph
- **Choice**: start at `https://docs.entro.security/`, extract navigable documentation links from authenticated HTML, normalize scheme/host/path, remove fragments and tracking queries, and crawl each canonical same-origin page once. Explicitly exclude authentication, logout, account, asset, and external URLs (including `descope.com` and `gitbook.com` login hosts).
- **Reason**: the new site has no confirmed public markdown catalog, so authenticated navigation is the page index.
- **Considered alternatives**: sitemap-only discovery and unrestricted BFS. Sitemap-only may omit protected pages; unrestricted BFS risks login routes and unbounded duplicates.

### D6: Render stable markdown behind a conversion seam
- **Choice**: separate fetching, link discovery, HTML-to-markdown conversion, and filesystem publication so fixtures can test each behavior. Preserve headings, prose, lists, tables, code, and links needed for later distillation; omit navigation chrome and scripts.
- **Reason**: the current direct markdown endpoint no longer exists, and crawl correctness must be testable without a live cookie.
- **Considered alternatives**: store raw HTML or screenshots. Rejected because downstream consumers require parseable text.

### D7: Publish atomically after complete validation
- **Choice**: write fetched pages and the generated README/index into a temporary sibling tree. Publish it to `documentation/` only when discovery is non-empty, every required page succeeds, conversion yields usable content, redaction passes, and index generation succeeds.
- **Reason**: direct writes can mix old and new sources or leave a partial tree after session and fetch failures.
- **Considered alternatives**: overwrite pages as fetched or accept partial publication. Rejected because either can silently corrupt the durable source.

### D8: No GitBook catalog fallback
- **Choice**: a failed protected-site crawl returns unsuccessful and leaves the existing tree intact.
- **Reason**: fallback would conceal that the authoritative, more complete source was unavailable.
- **Considered alternatives**: automatic or opt-in `entro.gitbook.io` fallback. Deferred because two source contracts would weaken completeness guarantees.

## Risks / Trade-offs

[Risk] The operator copies the wrong host's cookies (Descope instead of `docs.entro.security`) or an expired session. -> Mitigation: detect login redirects and print the numbered cookie steps; README says to copy the Cookie header from a request whose URL is still on `docs.entro.security` after login.

[Risk] Session cookies expire between copy and crawl. -> Mitigation: same rejected-session path; operator repeats login and export. Ingest does not persist or refresh cookies itself.

[Risk] Navigation markup changes and discovery misses pages. -> Mitigation: keep discovery isolated, record canonical visited URL counts, and include fixture plus live completeness checks.

[Risk] HTML-to-markdown conversion drops important structured content. -> Mitigation: test representative headings, tables, code blocks, lists, and links before publication.

[Risk] Existing index generation expects GitBook-shaped paths. -> Mitigation: define deterministic source-path mapping and require index validation against the staged tree before swap.

[Trade-off] Partial page failures discard staged output even though remaining pages are fetched. -> Reason for acceptance: durable source completeness is more important than publishing a mixed or partial snapshot.

## Migration Plan

1. Add fixture tests for cookie loading, Cookie-header injection, rejected login pages, URL normalization, bounded discovery, conversion, secret redaction, partial failures, and atomic publication.
2. Refactor the ingest CLI around authenticated fetch, discovery, conversion, and staging seams; change its default source to `https://docs.entro.security/`.
3. Document the operator cookie steps in README, `--help`, and failure messages without sample cookie values.
4. Run tests, then let the operator log in, export `ENTRO_DOCS_COOKIE`, and run live ingest locally.
5. Validate the staged page count, representative content, generated README, and Integration index before publishing `documentation/`.
6. Roll back code by restoring the previous ingest implementation; roll back content by restoring the prior committed `documentation/` tree. Never use the public GitBook catalog as an automatic runtime fallback.

Acceptance: fixture tests pass; a live run with a valid local cookie produces a non-empty same-origin markdown tree and valid indexes; missing/rejected cookies and any required-page failure return unsuccessful without changing the current tree and print the operator steps; repository scans show no cookie or authorization-header material.

## Open Questions

No blocking design questions. Cookie names stay operator-copied via the full `Cookie` header until a later change proves a stable single-name contract.
