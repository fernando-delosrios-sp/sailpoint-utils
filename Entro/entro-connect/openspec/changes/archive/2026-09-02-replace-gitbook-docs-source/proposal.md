## Why

The current documentation ingest relies on the public `entro.gitbook.io` markdown catalog, but that source is less complete than Entro's protected documentation site. Switching the authoritative source to `https://docs.entro.security/` gives downstream distillation a fuller input. The site uses GitBook visitor auth (Descope), so the operator must log in in a browser once and give ingest a session cookie via `.env` rather than HTTP Basic.

## What Changes

**Documentation source**
- From: public GitBook `llms.txt` and per-page markdown URLs.
- To: authenticated, same-origin discovery and capture from `https://docs.entro.security/`.
- Reason: the protected site is the more complete resource.
- Impact: breaking for operators who run documentation ingest because a local session cookie becomes required.

**Credential boundary**
- Operator logs in at `https://docs.entro.security/` in a browser, copies the request `Cookie` header, and stores it as `ENTRO_DOCS_COOKIE` in the gitignored `.env`.
- Ingest sends that value as the `Cookie` header; it does not drive Descope login or accept cookies on the command line.
- Missing, empty, expired, or rejected cookies fail before publishing and print the same operator steps.
- Never print, persist, or commit cookie values or `Cookie` / `Authorization` headers.

**Output safety**
- Keep `documentation/` as the durable output contract.
- Stage a crawl and replace source-derived output only after a valid non-empty capture; report page failures and return unsuccessful for partial runs.
- Do not automatically fall back to `entro.gitbook.io`.

## Non-goals

No Integration prep or Connection details distillation, `entro-connect` skill changes, vendor CLI automation, agent-visible secrets, crawler-driven browser login, HTTP Basic, or cleanup of historical crawler files and crawl blobs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `documentation-ingest`: replace key-free GitBook catalog ingest with session-cookie protected-site discovery, operator-facing cookie instructions, credential-safe failure behavior, and atomic documentation-tree publication.

## Impact

Affected areas are the documentation ingest CLI, its tests and fixtures, operator setup documentation (`README.md` plus CLI `--help` / missing-cookie errors), and regenerated source material under `documentation/`. The external system changes from `entro.gitbook.io` to `docs.entro.security`; no product API or downstream output path changes.
