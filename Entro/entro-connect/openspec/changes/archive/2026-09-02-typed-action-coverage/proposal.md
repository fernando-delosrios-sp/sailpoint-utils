## Why

A Connect run approved Azure onboarding and stalled: the catalog pointed at a
GitBook attachment the skill treated as unpinned. That file now downloads
anonymously (`?alt=media`, no token) and checksums
`sha256:af42cb707a3edce614ba23eed7aa14add8ee336142061dc775edb3d4409666d1`.
Other integration pages publish zips and in-page snippets; Copilot Studio still
names a customer-supplied `Entro-Onboard.ps1`. Configuring a target must use
bytes this repo holds, or a Typed action this project authored — never a signed
URL or a silent Prep step.

## What Changes

**Skill-held artifacts (scripts, zips, snippets)**
- From: Connect fetches `script.url` at Approve; checksums may be placeholders;
  files stay gitignored
- To: inventory every GitBook attachment under integration `documentation/`;
  anonymous GET; commit bytes + SHA-256 under both `entro-connect` skill trees;
  in-page onboarding snippets saved the same way; catalog names skill-relative
  path + checksum; Connect runs those files only
- Reason: GitBook tokens expire; anonymous origin is for ingest drift checks,
  not runtime
- Impact: breaking for Connect fetch; Azure Continuous (~22MB) and other
  integration zips enter git as normal blobs

**Per-step coverage**
- From: 24 of 51 Prep steps silent; unpublished scripts carry fake checksums
- To: every Prep step is a Skill-held artifact action, a Doc-derived Typed
  action, or Operator-only with reason and evidence. Unpublished files: inform,
  then Typed actions. Preferred Fit with a silent step is corrected
- Reason: silence is indistinguishable from UI-only
- Impact: additive per row; Copilot Automated path loses its unpinned script
  action

**Generator as source of truth**
- From: catalog JSON hand-edits; generator emits one skill catalog
- To: `catalog_contracts.py` owns pins and coverage; regenerate both catalogs
  and copy vendor files into `.agents/skills/entro-connect/` and
  `skills/entro-connect/`
- Reason: the next generate must not drop files or revert corrections
- Impact: non-breaking for the pipeline; dual skill trees stay in sync

## Non-goals

No secrets in agent context. No Entro API account creation, Connector
deployment, or per-integration skills. No change to Approve / Operation mode /
Orientation beyond checksum of skill-local files. No admin/legal attachments.
No Git LFS. No invented vendor commands.

## Capabilities

### New Capabilities

- None. Coverage and artifact pins belong to `documentation-ingest`; Connect
  disclosure to `integration-prep`; nouns to `ubiquitous-language`.

### Modified Capabilities

- `documentation-ingest`: require Skill-held copies + anonymous origin URL +
  SHA-256 for every integration-docs attachment and captured snippet; ingest
  fails on unpinned attachments or origin/skill checksum drift; every Prep step
  has an artifact action, Typed action, or Operator-only classification.
- `integration-prep`: Connect executes skill-local files only; Operator-only
  steps disclosed with reason; unpublished scripts do not block as fake pins.
- `ubiquitous-language`: add Skill-held onboarding artifact and Anonymous
  origin URL.

## Impact

`catalog_contracts.py`, `integration_catalog.py`, both `integrations.json`
catalogs, vendor files under both `entro-connect` trees, `entro-connect` fetch
docs (skill-local checksum), `tests/test_ingest_docs.py`, README if it describes
index fields, `CHANGELOG.md`. Vendor doc pages under `documentation/` remain
read-only source.
