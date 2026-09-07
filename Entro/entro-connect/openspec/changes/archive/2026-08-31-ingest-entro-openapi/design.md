## Context

Stage 1 already ingests GitBook Integration pages into the documentation tree. Entro also publishes a product API: the API docs portal loads OpenAPI 3 JSON from `GET {endpoint}/v1/docs` with header `Authorization` set to the API key (not Bearer). This change follows discovery: a separate ingest CLI writes a committed Entro OpenAPI snapshot beside that tree. The key never enters the repo.

## Architecture

[Container diagram](./diagrams/ingest-entro-openapi.drawio)

Operator runs `ingest_api.py` with `ENTRO_API_KEY` in the environment. The CLI GETs the Entro API catalog from the Entro API (default eval), redacts PAT-shaped example strings, rewrites `servers[0].url` to the fetch endpoint, and writes `documentation/api/openapi.yaml`. GitBook ingest is a different CLI and does not call `/v1/docs`.

## Goals / Non-Goals

**Goals:**

- Commit a full Entro OpenAPI snapshot (all published paths) as YAML.
- Fetch via the same contract the portal uses.
- Fail closed when the key is missing or `/v1/docs` fails; do not treat a missing or stale snapshot as success.
- Redact `ghp_` / `github_pat_` shaped strings before write.
- Keep GitBook ingest unchanged.

**Non-Goals:**

- Typed clients, codegen, or calling Entro mutation APIs.
- Integration automation or secrets-in-agent-runtime.
- Merging `ingest_docs.py` and `ingest_api.py`.
- Rewriting OAS2 leftover `host` / `basePath`.
- Scraping apidocs.entro.security HTML.

## Decisions

### D1: Separate CLI from GitBook ingest
- **Choice**: new `ingest_api.py`; do not add `/v1/docs` to `ingest_docs.py`.
- **Reason**: different auth, failure mode, and output; discovery locked two commands.
- **Considered alternatives**: subcommand on `ingest_docs.py`. Rejected to keep GitBook runs key-free.

### D2: Snapshot path and format
- **Choice**: `documentation/api/openapi.yaml` (YAML via PyYAML). Not part of cleaned nav.
- **Reason**: documentation folder already holds ingest output; YAML diffs better than minified JSON.
- **Considered alternatives**: repo-root `api/`; committed JSON; gitignored-only file. Rejected after location and snapshot decisions.

### D3: Auth and default tenant
- **Choice**: `ENTRO_API_KEY` required from the environment. Default endpoint `https://eval-api.entro.security`. Optional `--endpoint` (strip trailing slash). `Authorization` header is the raw key.
- **Reason**: matches the portal; eval is this workspace’s source of truth.
- **Considered alternatives**: Bearer prefix; committed key; default `api.entro.security`; required `--endpoint` with no default.

### D4: Transform before write
- **Choice**: parse JSON; require OpenAPI 3 `paths`; set `servers[0].url` to the fetch endpoint (create `servers` if missing); serialize YAML; run the same PAT redaction as GitBook ingest (`ingest_docs.redact_secrets`) on the YAML text.
- **Reason**: portal overwrites the vendor placeholder `https://api.test.com`; examples include `ghp_…`.
- **Considered alternatives**: commit raw JSON; filter to Integrations operations only.

### D5: Fail closed
- **Choice**: missing key, non-JSON, HTTP error, or missing `paths` → non-zero exit and do not write a successful snapshot (do not replace a good file with empty YAML).
- **Reason**: same idea as GitBook catalog fetch failure.
- **Considered alternatives**: write a stub file; continue without `paths`.

### D6: Tests vs live snapshot
- **Choice**: pytest with a fixture Entro API catalog (no live key). Apply also runs live ingest when the operator has `ENTRO_API_KEY` and commits `documentation/api/openapi.yaml`.
- **Reason**: CI cannot hold the key; the snapshot is the user-visible artifact.
- **Considered alternatives**: never commit YAML (gitignore). Rejected — agents need it without a key.

## Risks / Trade-offs

[Risk] Eval and production catalogs diverge. -> Mitigation: `--endpoint` override; default documented as eval.

[Risk] Example secrets in the catalog that are not GitHub PAT-shaped. -> Mitigation: reuse existing PAT redaction; extend later if new shapes appear. Do not log response bodies in tests that would print live tokens.

[Risk] Operator pastes the key into chat or a file. -> Mitigation: CLI reads env only; README states never commit the key.

[Trade-off] OAS2 `host` / `basePath` leftovers stay in the snapshot. -> Reason: non-goals; `servers[0]` is what clients should use.

[Trade-off] Two ingest CLIs. -> Reason: GitBook must stay runnable without Entro API credentials.

## Migration Plan

1. Add `ingest_api.py`, PyYAML dependency, and fixture tests.
2. Operator sets `ENTRO_API_KEY` locally, runs ingest, commits `documentation/api/openapi.yaml`.
3. Document the command in README. Leave `ingest_docs.py` unchanged.
4. Rollback: delete the new script, tests, YAML snapshot, and PyYAML dependency.

Acceptance: `python -m pytest` covers the delta scenarios; a live run with a local key writes OpenAPI 3 YAML at `documentation/api/openapi.yaml` with redacted PAT examples and `servers[0].url` equal to the endpoint used.

## Open Questions

None for this change. Deferred: codegen, mutation calls, single ingest CLI, OAS2 field cleanup.
