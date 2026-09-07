## Scope

Drop `connectorRequirement` and `connectorEvidence` from every Integration index row
because a connector is always required; leave Entro Connector topology pages
product-level and unchanged. Out of scope: per-row topology, SCIM / secrets /
versioning catalog fields, retitling the four topology pages.

## Language

**Connector requirement** (`conflicts-with-canonical` → supersede):
Whether a target's form needs a Worker Group. Retired: a connector is always
required, so the index must not ask the question.
_Avoid_: required / not-required / unknown on a row

**Requirement evidence** (`conflicts-with-canonical` → supersede):
The page-plus-quote that justified a connector requirement. Retired with that
field; Worker Group remains a connection-detail for later prep, not index evidence.
_Avoid_: evidence basis, worker-group-field-documented

**Connector deployment** (`draft` — keep canonical):
How the Entro Connector runtime is deployed (Docker Compose, Kubernetes Helm,
SaaS Perimeter, plus the existing Entro cloud page). Product-level, not a row
attribute.
_Avoid_: connector type on a target row, connectorRequirement

## Decisions

**Context** — Index rows still carry `required` / `unknown` plus a Worker Group
citation. That mixed "does this form need a connector?" with "how is the connector
runtime deployed?". Entro always needs a connector; the three deployment topologies
(Docker Compose, Kubernetes Helm, SaaS Perimeter) answer how and where, and already
live under `entro-connector/`.

**Q1 — Row shape?** Nothing extra. Connector always required; topologies stay
product-level docs.

**Q2 — Glossary?** Supersede Connector requirement and Requirement evidence.

**Q3 — Topology pages?** Leave the four product-level pages as they are.

## Open questions

None blocking.

## Scenarios discussed

- Every index row omits `connectorRequirement` and `connectorEvidence`
- Validation fails if either key is present
- Teams / Wiz / Salesforce / GDrive (formerly `unknown`) look like every other row
- Specs no longer name Connector requirement when describing the index
- Connector deployment remains the term for Docker / Helm / SaaS Perimeter pages
