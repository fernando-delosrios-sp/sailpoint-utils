## Scope

Capture Entro’s product API as a committed OpenAPI 3 snapshot under `documentation/api/openapi.yaml`, fetched by a new ingest command (default tenant `https://eval-api.entro.security`) using a local environment API key. Out: GitBook ingest changes, typed clients, calling mutation endpoints, storing the key, and Integration automation.

## Language

**Entro OpenAPI snapshot** (`promote`):
The committed OpenAPI 3 document of Entro’s product API, stored at `documentation/api/openapi.yaml` inside the documentation folder.
_Avoid_: swagger dump, portal HTML, apidocs page scrape, GitBook page

**Entro API catalog** (`promote`):
The machine-readable API definition Entro serves at `{endpoint}/v1/docs` (OpenAPI 3 JSON), which the API docs portal loads after login.
_Avoid_: GitBook markdown catalog, `llms.txt`, HTML scrape of apidocs.entro.security

**Documentation ingest** (`conflicts-with-canonical`):
Canonical today is GitBook Integration pages only. This change widens ingest to include the Entro API catalog as a second source, still without distillation or automation.
_Avoid_: treating `/v1/docs` as Integration onboarding markdown

**Documentation tree** (`draft` — do not promote here):
Unchanged: GitBook sidebar markdown under `documentation/`. The Entro OpenAPI snapshot is a sibling path (`documentation/api/`), not a sidebar group.
_Avoid_: listing `openapi.yaml` as a cleaned-nav page

## Decisions

Stage intent is documentation ingest (second source: Entro API catalog), not skills or CLI automation of Integrations.

Context → What to keep locally? → Full Entro OpenAPI snapshot (all published paths), not an Integrations-only subset.

Context → Where? → `documentation/api/openapi.yaml` (YAML), next to the documentation tree, not under `docs/` or `openspec/specs/`.

Context → How to refresh? → New `ingest_api.py`, separate from `ingest_docs.py`. Key from `ENTRO_API_KEY` only. Default endpoint `https://eval-api.entro.security`. `GET {endpoint}/v1/docs` with `Authorization` equal to the key (portal behavior; not `Bearer`).

Context → Secrets in examples? → Reuse GitBook PAT redaction (`ghp_` / `github_pat_`) before write. Never write the key to disk or the snapshot.

Context → `servers[0].url`? → Rewrite to the endpoint used for the fetch (eval by default). Leave OAS2 leftover `host` / `basePath` as published unless they contain secrets.

## Open questions

Deferred: typed client / codegen; calling `POST /v1/integrations/*`; merging GitBook and API ingest into one CLI; rewriting OAS2 leftover fields; rotating keys after a chat leak (operator action, not this change).

Assumed for design: PyYAML (or equivalent) to serialize OpenAPI YAML; missing or invalid key fails the run and MUST NOT treat a missing or stale snapshot as success.

## Scenarios discussed

- Successful fetch writes a redacted OpenAPI 3 YAML file at `documentation/api/openapi.yaml`.
- Missing `ENTRO_API_KEY` or HTTP failure on `/v1/docs` exits unsuccessful without committing a fake empty spec.
- Example bodies that contain `ghp_…` are stored as `ghp_<redacted>`.
- GitBook `ingest_docs.py` is unchanged and does not fetch `/v1/docs`.
- Snapshot includes Risk, Integrations, Identity Now, Entro API Keys, and remaining published tags — not a filtered subset.
