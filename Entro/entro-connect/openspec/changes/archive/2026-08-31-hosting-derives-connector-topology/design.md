## Context

`integrations.json` rows no longer carry connector requirement. Connector
deployment still exists as product-level docs under `entro-connector/`. The
operator rule that picks Docker Compose, Kubernetes Helm, or SaaS Perimeter
keys off whether the target endpoint is internet-reachable — a fact the index
does not record. `category` cross-cuts that fact. C4 is omitted: same catalog
writer and JSON file; no new containers.

## Goals / Non-Goals

**Goals:**

- Emit `hosting` on every row (`public` / `self-hosted` / `operator-selected`)
- Derive topology from hosting in a tested helper; do not store it on the row
- Name Hosting in the glossary; keep Connector deployment as the topology term

**Non-Goals:**

- A `connectorType` or `connectorDeployments` JSON key
- Splitting operator-selected targets into two rows
- Cataloguing SCIM, secret lineage, or connector versioning
- Retitling Entro Connector topology pages

## Decisions

### D1: Emit hosting; derive topology

- **Choice**: `integration_to_dict` emits `hosting`. A helper maps
  `public` → SaaS Perimeter; `self-hosted` → Docker Compose or Kubernetes Helm
  (Helm preferred when scanning is cluster-native); `operator-selected` →
  follow the operator's form choice. Validation fails if `hosting` is missing
  or not one of the three values. Rows MUST NOT carry topology keys.
- **Reason**: The rule is category-level in operator language but not in the
  index taxonomy; a constant topology on every row was already rejected.
- **Considered alternatives**: Spec prose with named exceptions — rejected,
  untestable. Derive from target-selection name heuristics — rejected, GitLab
  is one row with a checkbox. Store topology on the row — rejected, recreates
  the dropped field.

### D2: Three hosting values, not a list

- **Choice**: One of `public`, `self-hosted`, `operator-selected`. GitLab and
  n8n are `operator-selected`.
- **Reason**: Glossary forbids splitting a row on a form checkbox. A list of
  hostings would look like two topologies stored on the row.
- **Considered alternatives**: List of supported hostings — rejected. Dominant
  case only — rejected, hides the form. Worst-case self-hosted — rejected,
  GitLab.com would be labelled private.

### D3: No evidence citation for hosting

- **Choice**: Hosting is curated catalog judgement, not a Worker Group quote.
- **Reason**: Requirement evidence was superseded in drop-connector-requirement.
- **Considered alternatives**: Cite the GitLab "Self managed" checkbox page —
  rejected, that is a connection-detail for later prep.

### D4: Wire the unused topology constants into the helper

- **Choice**: Reuse `ConnectorDeployment` / `CONNECTOR_TOPOLOGY_PAGES` for the
  derivation result and doc links. Derived values are the three operator
  topologies (SaaS Perimeter, Docker, Helm). Entro cloud stays a product-level
  page, not a hosting mapping.
- **Reason**: Those constants are currently unreferenced dead code.
- **Considered alternatives**: New types — rejected, duplicates the glossary.

## Risks / Trade-offs

[Risk] Curated hosting is wrong for a dual-mode product labelled `public` →
Mitigation: use `operator-selected` whenever the form documents both.

[Trade-off] Operators still choose Docker vs Helm for self-hosted targets →
Accepted: the helper allows both; Helm is only a preference for cluster-native
scanning, not a stored field.

## Migration Plan

N/A — regenerate `documentation/integrations.json`. Acceptance:
`.venv/bin/python -m pytest` green and `openspec validate --all --json` all valid.

## Open Questions

None.
