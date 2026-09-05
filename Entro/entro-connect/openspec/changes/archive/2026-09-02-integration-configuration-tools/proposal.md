## Why

The Integration index names targets, setup methods, and Coverages, but not which local
CLI an operator or agent should use for Integration prep. Later automation is supposed
to use vendor CLIs the user authenticates once; without a catalog, agents invent tools
or ask for secrets. Record Configuration tools and OS install now so that stage has a
contract.

## What Changes

**Configuration tools on each target**
- From: rows have setup and authentication methods only
- To: each row lists `configurationTools` (`binary` + `fit`); Coverages may add extras
- Reason: Copilot Studio inherits Microsoft Ecosystem tools; GitHub S3 streaming needs `aws`
- Impact: additive JSON; no runtime consumers yet

**Tool install catalog at index root**
- From: no install or auth-once data
- To: `toolInstall` keyed by binary — `authOnce`, credential boundary, Windows / macOS /
  Linux preferred install plus `docsUrl`
- Reason: `az` is shared; install must not be copied onto every row
- Impact: additive root object; validation fails if a non-`none` binary is missing

## Non-goals

No Integration automation, skills, or running vendor CLIs. No secrets in agent context
or committed files. No ingest fetch changes. Exact package ids are pinned at apply
against vendor pages. No new capability domain.

## Capabilities

### New Capabilities

- None. Configuration tools belong to `documentation-ingest`; nouns belong to
  `ubiquitous-language`.

### Modified Capabilities

- `documentation-ingest`: each target MUST list Configuration tools; the index MUST
  carry `toolInstall`; Coverages MAY add tools; references MUST resolve except `fit: none`.
- `ubiquitous-language`: add Configuration tool, Tool install catalog, Fit, and
  Credential boundary.

## Impact

`integration_catalog.py`, regenerated `documentation/integrations.json`,
`tests/test_ingest_docs.py`, README / ingest README if they describe index fields,
`CHANGELOG.md`. GitBook fetch unchanged.
