## Why

GitBook ingest captures Integration onboarding pages. Entro also publishes a machine-readable product API (`GET {endpoint}/v1/docs`) behind the API docs portal. Later automation of `POST /v1/integrations/*` and related operations needs that contract locally. Fetch it once, redact example secrets, and commit an OpenAPI snapshot so agents do not scrape the portal or handle keys at read time.

## What Changes

**Entro API catalog ingest**
- From: no local Entro product API definition
- To: `ingest_api.py` GETs `{endpoint}/v1/docs` (default `https://eval-api.entro.security`) with `Authorization` from `ENTRO_API_KEY`, redacts PAT-shaped examples, rewrites `servers[0].url` to the fetch endpoint, writes `documentation/api/openapi.yaml`
- Reason: same ingest idea as GitBook, different source
- Impact: non-breaking; new script and snapshot; `ingest_docs.py` unchanged

**Glossary**
- From: Documentation ingest means GitBook Integration pages only
- To: Documentation ingest also covers the Entro API catalog; add Entro OpenAPI snapshot and Entro API catalog
- Reason: two sources under one documentation folder without calling YAML a documentation-tree page
- Impact: spec and README language only

## Non-goals

No typed client or codegen. No calling Entro mutation APIs or Integration automation. No storing or logging API keys (operator supplies `ENTRO_API_KEY` locally). No GitBook ingest changes. No merging the two ingest CLIs. No rewriting OAS2 leftover `host` / `basePath`. Key rotation after a leaked chat token is an operator action, not this change.

## Capabilities

### New Capabilities

- None. Entro API catalog ingest belongs in existing `documentation-ingest`. Glossary terms belong in `ubiquitous-language`.

### Modified Capabilities

- `documentation-ingest`: MUST fetch the Entro API catalog into a committed Entro OpenAPI snapshot; fail closed without a key or when `/v1/docs` fails; redact PAT-shaped strings; MUST NOT mix this fetch into GitBook ingest.
- `ubiquitous-language`: add Entro OpenAPI snapshot and Entro API catalog; widen Documentation ingest notes so GitBook and `/v1/docs` are both ingest sources.

## Impact

New Python CLI `ingest_api.py`, tests, YAML dependency, `documentation/api/openapi.yaml`, README how-to. External system: eval (or override) Entro API. GitBook ingest, `documentation/integrations.json`, and `docs/` unchanged.
