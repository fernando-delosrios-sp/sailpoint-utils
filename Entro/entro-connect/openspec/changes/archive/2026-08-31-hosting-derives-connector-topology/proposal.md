## Why

After dropping connector requirement, nothing in the index records how an
operator should deploy the Entro Connector. The operator rule maps public
endpoints to SaaS Perimeter and private ones to Docker or Helm, but index
`category` mixes both. GitLab and n8n even let the operator pick hosting in
the form. Capturing hosting on the row makes that rule testable without
bringing a topology key back.

## What Changes

**Index records hosting**
- From: rows have no reachability fact; topology lives only in product docs
- To: each row has `hosting`: `public`, `self-hosted`, or `operator-selected`
- Reason: category cannot distinguish AWS from Vault, or GitHub Cloud from GitHub Enterprise Server
- Impact: additive JSON field; regenerate `integrations.json`

**Topology is derived, not stored**
- From: no machine-readable mapping from a target to Docker / Helm / SaaS Perimeter
- To: a helper maps hosting to topology; rows MUST NOT emit a topology list
- Reason: storing type would reintroduce the dropped per-row connector field
- Impact: tests assert the derivation; README explains the mapping

**Glossary names Hosting**
- From: Connector deployment is documented only as product-level pages
- To: Hosting is a live term; Connector deployment Notes state the derivation
- Reason: operators and specs must not say "connector type on the row"
- Impact: ubiquitous-language delta

## Non-goals

No per-row stored topology or allowed-topology lists. No SCIM, encrypted-secrets,
or versioning catalog fields. No rewrite of Entro Connector pages. No secrets
handling. No splitting GitLab or n8n into two rows.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `documentation-ingest`: each row MUST carry `hosting`; validation MUST reject a missing or unknown value; topology MUST be derived from hosting and MUST NOT appear as a row key.
- `ubiquitous-language`: add Hosting; extend Connector deployment Notes with the derivation rule.

## Impact

`integration_catalog.py` (row model, validation, derivation helper, every
`INTEGRATIONS` entry), `documentation/integrations.json`,
`tests/test_ingest_docs.py`, README and `documentation/README.md` blurbs,
`CHANGELOG.md`.
