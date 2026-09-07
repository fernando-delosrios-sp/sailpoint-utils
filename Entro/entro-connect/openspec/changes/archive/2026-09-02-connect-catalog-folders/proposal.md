## Why

The Skill catalog is one ~152KB JSON plus `vendor/` keyed by GitBook slugs. A Connect run that opens that file loads every tile's Prep steps before Lock. The skill already discloses procedure by file; the catalog should disclose the same way: index until Lock, then one target. Architecture bar: one Row catalog in context after Lock, still one skill, still generated data.

## What Changes

**Skill catalog layout**
- From: one fat `integrations.json` (`toolInstall` inline) and `vendor/<gitbook-slug>/`
- To: thin Skill catalog index (`integrations.json`), sibling Tool install file (`tool-install.json`), one row folder per Add New Account target with `catalog.json` (today's full row object) and artifacts beside it; `catalogPath` on the index; retire skill-side `vendor/`
- Reason: Lock must not load other tiles or every CLI probe
- Impact: catalog writer, both skill trees, tests; breaking for anything that assumed a single skill JSON array of full rows

**Connect run reads**
- From: open `integrations.json` for the whole catalog at Lock
- To: Orientation and Lock use the index only; open `catalogPath` after Lock; tools.md opens Tool install file after Lock and only the locked binaries
- Reason: the architecture bar
- Impact: SKILL.md, lock-target.md, tools.md, prep.md (`skillPath` still skill-root-relative)

**Ingest index**
- From / To: `documentation/integrations.json` stays one full-row file (page paths allowed)
- Reason: Connect never needed the docs tree; smaller contract
- Impact: writer emits two shapes

## Non-goals

No per-integration skills. No splitting `documentation/integrations.json`. No method- or Coverage-sliced JSON. No secrets in agent context. No Connector deploy. No changing Prep/Typed-action semantics except paths. No GitBook fetch at Connect time.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `documentation-ingest`: Skill catalog is a generated tree (index, Tool install file, row folders); validation; Skill-held paths; both skill trees identical
- `integration-automation`: Connect reads index until Lock, then one Row catalog; no `documentation/` pages
- `integration-prep`: `skillPath` under row folders, skill-root-relative; checksum before Approve unchanged
- `ubiquitous-language`: Skill catalog, Skill catalog index, Row catalog, catalogPath, Tool install file; Skill-held and Add New Account target notes

## Impact

`integration_catalog.py` (and contracts/tests), `.agents/skills/entro-connect/` and `skills/entro-connect/`, README, ADR-0001 supersession (ADR-0002 at apply), `CHANGELOG.md`. Ingest of GitBook pages unchanged. Hand-edits of generated skill JSON still overwritten.
