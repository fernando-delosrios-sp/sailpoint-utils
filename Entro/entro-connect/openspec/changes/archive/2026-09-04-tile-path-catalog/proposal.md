## Why

The catalog keys integrations by documentation-era `targetSelection` and separate Setup/Authentication methods, but Entro's Select Provider UI shows **58 tiles** and each connection form exposes **one visible path choice** (radio cards, token types, protocols). Operators and Connect Lock must match what Entro actually presents — not four Atlassian targets or GitHub rows split by legacy doc structure.

## What Changes

**Row identity**
- From: 36 rows keyed by `(tile, targetSelection)` with Setup/Authentication methods and pre-selected Coverages
- To: **58 rows**, one per Select Provider tile; `integrationPaths[]` replaces target/setup/auth; optional capabilities replace Coverages as just-in-time choices
- Reason: UI alignment and simpler Lock
- Impact: breaking catalog contract; regenerate all JSON trees; rewrite validators and Connect procedure files

**Lock workflow**
- From: tile → target → Coverage multi-select → Setup → Authentication
- To: tile → Integration path (when >1) → stop on capture-required stubs; optional capabilities consented just-in-time during Prep
- Reason: matches operator workflow and bundled-script limits (Microsoft fork)

**Inventory**
- From: 27 documented tiles, 9 duplicate target rows
- To: 58 tiles (27 consolidated + SharePoint/OneDrive split + 29 additional UI tiles);
  31 rows are capture-required until the two split forms and 29 additional forms are captured
- Reason: screenshot is authoritative provider list

## Non-goals

No Entro product API changes. No Connect-time GitBook fetch. No completing all 58 connection forms in this change. No change to `complete-gcp-connect-actions` uncommitted files.

## Capabilities

### Modified Capabilities

- `documentation-ingest`: Integration index keyed by tile; `integrationPaths`; optional capabilities; capture-required stubs; folder slug `kebab(tile)` only
- `ubiquitous-language`: Integration, Integration path, Optional capability, Capture required; retire target/setup/auth/Coverage as Lock dimensions
- `integration-automation`: Lock tile + path; capture-required stop; just-in-time optional capability consent
- `integration-prep`: Prep resolves from locked Integration path; optional capability branches after operator choice
- `connection-details`: Field map from locked path only

## Impact

`integration_catalog.py`, `integration_catalog_migration.py`, `catalog_contracts.py`, `skill_held.py`, both `entro-connect` skill trees, `documentation/integrations.json`, `tests/test_ingest_docs.py`, `docs/adr/0003-tile-path-catalog.md` (supersedes ADR-0002 folder slug rule), `CHANGELOG.md`, `README.md`, `AGENTS.md` entro-connect line.
