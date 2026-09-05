# Entro integrations

Tooling to manage SailPoint Entro Integrations: ingest published docs, then (later) distill **integration prep** and **connection details**, and eventually CLI **integration automation**. The agent never handles secrets — you authenticate vendor CLIs locally.

## Stage 1 (current)

Capture Entro’s Integration documentation as a local **documentation tree** so later work can parse the same hierarchy operators see on the protected documentation source.

| Path | Role |
|------|------|
| `documentation/` | Documentation tree (ingest output). Folders match documentation sidebar groups. Includes `integrations.json`. |
| `documentation/api/openapi.yaml` | Entro OpenAPI snapshot (product API catalog). Sibling of the tree, not a documentation page. |
| `docs/` | Agent process docs (routing, issue tracker, triage). Not vendor pages. |
| `ingest_docs.py` | Fetches the protected documentation source at `https://docs.entro.security/` with `ENTRO_DOCS_COOKIE`. Does not call `/v1/docs` or need `ENTRO_API_KEY`. Does not fall back to the public GitBook catalog. |
| `ingest_api.py` | Fetches the **Entro API catalog** (`GET {endpoint}/v1/docs`) and writes the OpenAPI snapshot. |
| `integration_catalog.py` | Curated Select Provider tiles (58). Writes ingest `documentation/integrations.json` (one file of full rows per tile, with `integrationPaths`, `optionalCapabilities`, Method waivers, and fork census) and a Skill catalog tree in both `.agents/skills/entro-connect/` and `skills/entro-connect/`: thin index `integrations.json` (`integrationPathNames`, `optionalCapabilityNames`, `captureRequired`), Tool install file `tool-install.json`, and `integrations/<kebab-tile>/catalog.json` plus Skill-held artifacts in the tile folder. Capture-required stubs reserve tiles before form capture. Curation bookkeeping is stripped from Skill catalog trees. Completeness validation requires every page under the integration documentation folders to be cited or waived. A Local onboarding fork also records `localFork` and `originChecksum`; ingest may emit an origin-published notice (keep-local vs take-remote) without overwriting Skill-held bytes. Tool install Configure once, when present, holds `methods` — one Authentication route per way in, each with `whenToPick`, its own `check`, `prompts` (`prompt` + `whereToFind`, optional `secret`), `credentialBoundary`, `docsUrl`, and an `authOnce` that is null when the route has no sign-in. |
| `.agents/skills/entro-connect/` | Model-invoked Connect skill. Orientation and Lock read the Skill catalog index only; after Lock, open that tile's `catalogPath` Row catalog. Lock confirms tile and Integration path (not optional capabilities). Never open `documentation/` pages. Connect checksums `script.skillPath` locally and does not fetch GitBook. Connect logs and temporary run files live in the gitignored `integrationConfig/` Connect run folder under the current working directory. |
| `crawl_docs.py`, `integrations*.md` | Previous HTML crawl. Left in place; not the documentation tree. |

## Ingest

Export a session cookie, then run documentation ingest:

1. Open `https://docs.entro.security/` in a browser.
2. Complete login until documentation pages are visible.
3. In DevTools Network, select a document request whose URL is still on `docs.entro.security`, open **Headers**, and copy the full `Cookie` request header value (every `name=value` pair, separated by semicolons). Do not copy cookies one at a time from the Cookies panel.
4. Set `ENTRO_DOCS_COOKIE` to that value in the repo-local `.env` file.
5. Run `python ingest_docs.py`.

If the cookie expires or ingest reports a rejected session, repeat steps 1–5. Ingest does not refresh cookies itself.

```bash
python ingest_docs.py
python ingest_docs.py https://docs.entro.security/ -o documentation
python ingest_docs.py --help

export ENTRO_API_KEY  # set locally; never commit the key
python ingest_api.py
python ingest_api.py --endpoint https://eval-api.entro.security
python ingest_api.py --help
```

Default documentation start URL is `https://docs.entro.security/`. Ingest sends `ENTRO_DOCS_COOKIE` as the `Cookie` header. It does not accept cookies on the command line and does not fall back to `entro.gitbook.io`. Default API endpoint is `https://eval-api.entro.security`. `ingest_api.py` sends `Authorization` as the raw key (not Bearer). Trailing slashes on `--endpoint` are stripped. The snapshot is YAML at `documentation/api/openapi.yaml`; it is independent of documentation ingest.

Token-shaped GitHub PATs in page bodies are replaced with placeholders before write. Cookie values and `Cookie` / `Authorization` headers are never printed.

A successful run stages pages, `documentation/README.md`, and `documentation/integrations.json`, then replaces `documentation/` only when discovery is non-empty, every required page converts, redaction succeeds, and indexes validate. Partial page failures are reported; remaining pages are still attempted; staged output is discarded and the previous tree is left unchanged. The same write emits a Skill catalog tree in both `entro-connect` skill folders (index, Tool install file, row folders; no `documentation/` markdown paths; no skill-side `vendor/`). A connector is always required. The entro-connect skill does not read the documentation tree. A Connect run creates the Connect log after Lock, persists Intro before Operation mode, and offers automated only when the selected Typed action plan is complete. Connect checksums skill-local files before it announces or gates the action and does not download from GitBook — including a Local onboarding fork, where Connect verifies `checksum` only and never fetches `originChecksum`. Automated runs each cataloged action itself after announcing it, secret-producing scripts included, with that output routed away from agent context; supervised gates each action and the operator runs it. Connect logs keep the `entro-*.md` naming pattern inside the Connect run folder; Temporary script copies and Secret sinks live beside them with `tmp-` and `sink-` prefixes. The repository-root folder is gitignored as `/integrationConfig/`. Docker Compose, Kubernetes Helm, and SaaS Perimeter stay in product-level Entro Connector docs.

## Tests

```bash
python -m pytest
```

Python 3.11+ (`pyproject.toml`). Use a venv if the system Python is PEP 668–managed: `python3 -m venv .venv && .venv/bin/pip install pytest && .venv/bin/python -m pytest`.

## Secrets

Do not commit credentials, `ENTRO_DOCS_COOKIE`, or `ENTRO_API_KEY`. Keep them in the environment or a gitignored `.env`. Documentation ingest reads only `ENTRO_DOCS_COOKIE` from that file. Both ingest commands redact `ghp_` / `github_pat_` strings that look like live tokens. Distillation must still describe fields, not copy sample secrets.

## Specs and changelog

- Vocabulary: `openspec/specs/ubiquitous-language/spec.md`
- Ingest contract: `openspec/specs/documentation-ingest/spec.md`
- Integration prep: `openspec/specs/integration-prep/spec.md`
- Architecture pictures: `openspec/specs/architecture-diagrams/spec.md` — C4 flowcharts (mermaid `flowchart` inline in `design.md`)
- Release notes: `CHANGELOG.md`
