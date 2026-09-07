## 1. Catalog writer and contracts

- [x] 1.1 Extend `catalog_contracts.py` with Skill catalog index shape (`tile`, `targetSelection`, `summary`, `setupMethodNames`, `authenticationMethodNames`, `coverageNames`, `catalogPath`), slug from Entro identity, and Tool install file schema (today's `toolInstall` object)
- [x] 1.2 Change `integration_catalog.py` to write ingest `documentation/integrations.json` unchanged as full rows; write both skill trees as index + `tool-install.json` + `integrations/<slug>/catalog.json` (complete row object); set `skillPath` skill-root-relative into the row folder; omit `documentation/` paths from Row catalogs
- [x] 1.3 Stop writing skill-side `vendor/`; copy Skill-held artifacts into the owning row folder; collapse AWS duplicate GitBook trees into `integrations/aws/`
- [x] 1.4 Fail validation when index is fat, `catalogPath` missing or mismatched to Row catalog identity, skill trees differ, `vendor/` remains, or a pin still uses `vendor/`

## 2. entro-connect read path

- [x] 2.1 Rewrite `.agents/skills/entro-connect/SKILL.md` and `lock-target.md` so Orientation and Lock read only the Skill catalog index (Coverage names resolve parent); open `catalogPath` only after Lock; no per-folder `SKILL.md`
- [x] 2.2 Rewrite `tools.md` to open `tool-install.json` after Lock and read only locked `binary`/`id` keys; rewrite `prep.md` so `skillPath` stays skill-root-relative under the row folder and never `vendor/`
- [x] 2.3 Keep `skills/entro-connect/` in lockstep with `.agents/skills/entro-connect/` (procedure files and generated tree)

## 3. Verification

- [x] 3.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 3.2 Named tests: Skill catalog tree written with ingest index; index has no `prepSteps`/`typedActions`/`connectionFields`/`toolInstall`; GitHub is three row folders; `toolInstall` only in `tool-install.json`; no `vendor/` in either skill tree; both trees identical
- [x] 3.3 Named tests: Row catalog has `summary` / fields / steps without `documentation/` paths; Azure script `skillPath` under `integrations/microsoft-ecosystem/`; Copilot Studio is a Coverage name on the Microsoft Ecosystem index entry
- [x] 3.4 Named tests or skill-file assertions: lock-target.md does not instruct opening `catalog.json` before Lock; tools.md does not instruct reading `tool-install.json` before Lock; SKILL.md forbids `documentation/` pages
- [x] 3.5 Run `openspec validate --all --json` and `.venv/bin/python -m pytest`

## 4. Documentation

- [x] 4.1 Update `README.md` Skill catalog path, tree layout, and that Connect reads the index then one Row catalog
- [x] 4.2 Write `docs/adr/0002-skill-catalog-tree.md` (supersedes ADR-0001's single skill JSON file; keeps one skill and no documentation-tree dependency); add supersession note on ADR-0001
- [x] 4.3 Skip Entro OpenAPI — no API contract change
- [x] 4.4 Skip CLI `--help` — no public CLI surface

## 5. Changelog

- [x] 5.1 Create or update changelog entry for this change via changelog-generator
- [x] 5.2 Confirm the entry names Skill catalog index, Row catalog folders, Tool install file, retired `vendor/`, and that ingest `documentation/integrations.json` stays one file
