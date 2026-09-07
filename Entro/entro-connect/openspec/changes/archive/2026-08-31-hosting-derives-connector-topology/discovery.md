## Scope

Add a `hosting` attribute on every Integration index row (`public`,
`self-hosted`, or `operator-selected`) and record the rule that derives Entro
Connector deployment topology from hosting. Out of scope: storing topology on
the row, per-row recommended-topology lists, SCIM / encrypted-secrets /
versioning catalog fields, rewriting Entro Connector topology pages.

## Language

**Hosting** (`promote`):
Whether the target's connection endpoint is internet-reachable (`public`),
inside the customer's private network (`self-hosted`), or chosen by the operator
inside the connection form (`operator-selected`).
_Avoid_: connector type on a row, category as a stand-in for reachability

**Connector deployment** (`draft` — keep canonical, extend Notes):
How the Entro Connector runtime is deployed. Derived from Hosting: `public` →
SaaS Perimeter; `self-hosted` → Docker Compose or Kubernetes Helm; `operator-selected`
follows the form choice. Not stored on the row.
_Avoid_: connector type as a JSON key, Entro cloud as a derived value from hosting

## Decisions

**Context** — The operator rule maps target kind to one of three topologies
(Docker Compose, Kubernetes Helm, SaaS Perimeter). Index `category` cannot
supply that: public cloud and private vaults share `cloud-and-infrastructure`;
GitHub Cloud and GitHub Enterprise Server share `code-and-ci-cd`. Some forms
(GitLab, n8n) let the operator pick hosting.

**Q1 — Where does the rule live?** Spec + derivable helper, no per-row topology
key.

**Q2 — What supplies public vs private?** A row attribute `hosting`.

**Q3 — Dual-mode forms?** Three values: `public`, `self-hosted`,
`operator-selected`. For `operator-selected`, topology follows the form choice.

**Assumptions (not gated):** `hosting` is emitted on `integrations.json`;
derived topology is not. Hosting needs no evidence citation. Helm is the
preferred self-hosted topology when scanning is cluster-native; otherwise Docker
or Helm are both allowed. Entro cloud stays a product-level page, not a derived
value. SCIM, encrypted secrets, and connector versioning stay product-level docs.

## Open questions

None blocking.

## Scenarios discussed

- Every row carries `hosting` with one of the three values
- Public rows derive SaaS Perimeter
- Self-hosted rows derive Docker Compose or Kubernetes Helm
- Operator-selected rows (GitLab, n8n) do not pick a single topology
- Validation rejects an unknown hosting value or a missing key
- Rows still MUST NOT carry `connectorRequirement`, `connectorEvidence`, or a
  stored topology list
