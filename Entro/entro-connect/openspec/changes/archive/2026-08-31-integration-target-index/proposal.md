## Why

`documentation/integrations.json` contradicts itself. Amazon Web Services appears twice: the
CloudFormation row claims its connection form needs no Worker Group, while the Manual Assume
Role row documents the Worker Group field on that same form. The cause is row identity — rows
were split by setup method rather than by the form the operator actually sees, and each split
row then had its connector requirement guessed from whether one page happened to print a
Worker Group field. Six rows are wrong today. Fixing this now matters because integration-prep
and connection-details work is about to read this index as its source of truth.

## What Changes

**Row identity**
- From: one row per documentation section and setup method
- To: one row per Add New Account target — the tile, plus any explicit in-form target choice
- Reason: setup methods share a connection form, so rows split that way can contradict each other
- Impact: breaking for readers of `integrations.json`; no external contract, no consumers yet

**Connector requirement**
- From: guessed per page; absence of a Worker Group field read as `not-required`
- To: `required` or `not-required` only with a citation; page silence yields `unknown`
- Reason: absence of a field on one page is not evidence about the form
- Impact: corrects AWS, Microsoft Ecosystem, Google Cloud Platform, Wiz, Google Drive, SharePoint

**Connector fields**
- From: `connectorDeployments` and `connectorDocumentation`, identical on every row
- To: removed, replaced by one requirement-evidence citation per row
- Reason: neither field distinguished any row; the second was evidence in name only
- Impact: the four connector topologies stay documented once, at product level

**Validation**
- From: internal shape only — passes on self-contradictory data
- To: citations must resolve to ingested files; non-`unknown` rows must carry one
- Reason: the defect survived because nothing checked claims against the docs

## Non-goals

No integration-prep or connection-details distillation. No change to how ingest fetches or
filters pages. No skills, no CLI automation, no secrets handling. No re-crawl of GitBook — the
already-ingested `documentation/` tree is the evidence base. No per-target permission or
scope modelling.

## Capabilities

### New Capabilities

- None. Target rows and requirement evidence belong to `documentation-ingest`; the vocabulary
  belongs to `ubiquitous-language`.

### Modified Capabilities

- `documentation-ingest`: the integration index MUST be keyed by Add New Account target, and
  every connector requirement MUST carry resolvable evidence or be `unknown`.
- `ubiquitous-language`: add Add New Account target, Setup method, Authentication method,
  Connector requirement, and Requirement evidence; supersede Integration variant.

## Impact

`integration_catalog.py` (row model, connector fields, validation), `documentation/integrations.json`
(regenerated, fewer rows), `tests/test_ingest_docs.py` (new cases for citation resolution and
target collapsing), `CHANGELOG.md`. No change to `ingest_docs.py` fetching. GitBook remains the
upstream source but is not called by this change.
