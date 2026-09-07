## Why

Collapsing Microsoft Copilot Studio into the Microsoft Ecosystem row stopped the catalog
from inventing a tile the Add New Account provider list does not have, but it left no
name for what that GitBook section is. SharePoint is already in the same unnamed bucket.
GitHub real-time scanning, CrowdStrike RTR, Jira real-time scanning, and SailPoint NHI
aggregation are the same shape on other targets. Skills that later answer "turn on
Copilot Studio" need Coverage as a first-class child of a target, or they will keep
minting fake tiles.

## What Changes

**Coverage on each target row**
- From: a target's extra GitBook sections are only more paths in `documentation`
- To: each row carries `coverages`, each with a name and its pages; core onboarding
  stays on the row, not as a Coverage
- Reason: operators ask for surfaces, not documentation folders
- Impact: additive JSON field; no consumers yet

**How a Coverage is identified**
- From: a documented Add New Account path is treated as a tile even when the provider
  list has no such tile
- To: the provider list wins; a section that names a missing tile is Coverage of the
  real target, evidenced by that collapsed section
- Reason: GitBook navigation paths can lag the UI
- Impact: Copilot Studio stays off the tile list; Copilot chats stay off Coverages
  until they have a section

**Populate from the ingested tree**
- From: Microsoft Ecosystem lists SharePoint and Copilot pages with no Coverage names
- To: named Coverages for every collapsed section already in `documentation/`
  (Ecosystem: SharePoint / OneDrive, Copilot Studio; GitHub RTS on each GitHub row;
  GitHub S3 log streaming on Cloud rows; Falcon RTR on CrowdStrike; Jira RTS on
  Atlassian / Jira Cloud; SailPoint NHI aggregation on ISC)
- Reason: the rule is useless if only Microsoft is filled in
- Impact: curated catalog constants plus tests; ingest fetch unchanged

## Non-goals

No integration-prep or connection-details distillation. No ingest fetch or nav-filter
changes. No skills or CLI automation. No secrets handling. Git clone scanning stays
product-level. Permission-group-only surfaces (Copilot chats, Defender, Teams secrets)
are not Coverages. Azure Hybrid, continuous Key Vault, and Okta custom role stay extra
core prep, not Coverages.

## Capabilities

### New Capabilities

- None. Coverage belongs to `documentation-ingest`; the noun belongs to
  `ubiquitous-language`.

### Modified Capabilities

- `documentation-ingest`: each Integration index row MUST list its Coverages; a
  Coverage MUST cite ingested pages from a collapsed GitBook section, not from a
  permission-group heading alone.
- `ubiquitous-language`: add Coverage; Notes on Add New Account target MUST state that
  a documented navigation path naming a missing tile is Coverage evidence, not a new
  target.

## Impact

`integration_catalog.py` (Coverage model, inventory, validation),
`documentation/integrations.json` (regenerated), `tests/test_ingest_docs.py`,
`CHANGELOG.md`. No change to `ingest_docs.py` fetching. GitBook is evidence, not a
runtime dependency.
