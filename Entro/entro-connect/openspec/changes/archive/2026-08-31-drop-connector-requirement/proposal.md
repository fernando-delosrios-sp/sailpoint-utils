## Why

`connectorRequirement` asked whether a target needs a connector. In Entro that is
always yes. The flag and its Worker Group citations mixed form-field evidence with
deployment architecture (Docker Compose, Kubernetes Helm, SaaS Perimeter), which
already lives in product-level Entro Connector docs. Dropping both fields stops the
index from pretending some targets connect without a connector.

## What Changes

**Index drops connector fields**
- From: each row has `connectorRequirement` (`required` / `not-required` / `unknown`) and optional `connectorEvidence`
- To: neither key exists; a connector is assumed
- Reason: the question is not a per-target fact
- Impact: breaking JSON contract; regenerate `integrations.json`

**Glossary supersedes the two terms**
- From: Connector requirement and Requirement evidence are live index vocabulary
- To: both marked superseded; Connector deployment stays for product-level topologies
- Reason: operators should not say "not-required connector"
- Impact: specs and tests stop using those terms for the index

## Non-goals

No per-row recommended or allowed topology. No SCIM, encrypted-secrets, or
versioning catalog fields. No rewrite of the four Entro Connector topology pages.
No Worker Group connection-detail distillation. No secrets handling.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `documentation-ingest`: index rows MUST omit `connectorRequirement` and `connectorEvidence`; the evidence requirement is removed.
- `ubiquitous-language`: supersede Connector requirement and Requirement evidence; Add New Account target terms no longer define them.

## Impact

`integration_catalog.py` (types, `_row`, validation, serialization),
`documentation/integrations.json`, `tests/test_ingest_docs.py`, README and
`documentation/README.md` blurbs, `CHANGELOG.md`.
