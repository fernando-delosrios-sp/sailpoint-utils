## Context

`integrations.json` still emits `connectorRequirement` and `connectorEvidence` from
`IntegrationDefinition`. Rows without a documented Worker Group field are `unknown`.
Product-level Entro Connector topology pages already exist under `entro-connector/`
and MUST NOT appear as target rows. This change does not re-fetch GitBook.

C4 is omitted: same catalog writer and JSON file; no new containers.

## Goals / Non-Goals

**Goals:**

- Remove `connectorRequirement` and `connectorEvidence` from the index contract
- Treat a connector as always required, with no per-row flag
- Supersede the two glossary terms
- Keep Connector deployment as product-level documentation

**Non-Goals:**

- Putting Docker / Helm / SaaS Perimeter on each row
- Changing `entro-connector/` page set or titles
- Cataloguing SCIM, secret lineage, or connector versioning
- Distilling Worker Group as a connection-detail field

## Decisions

### D1: Drop both fields; do not replace them

- **Choice**: `integration_to_dict` omits both keys. `_row` no longer takes
  `connector_requirement` or `connector_evidence`. Validation fails if either key
  is present on a row.
- **Reason**: A constant `required` on every row is noise; a topology field was
  explicitly rejected.
- **Considered alternatives**: Recommended topology per row — rejected, mapping is
  category-level and some targets allow Docker or Helm. Allowed-topology lists —
  rejected, same expansion. Keep Worker Group citations as generic evidence —
  rejected, they only existed to justify the dropped flag.

### D2: Formerly `unknown` rows are not special

- **Choice**: Microsoft Teams, Wiz, Salesforce, and Google Workspace (GDrive) lose
  the fields like every other row.
- **Reason**: `unknown` meant "docs did not mention Worker Group", not "no connector".
- **Considered alternatives**: A residual `unknown` — rejected, that recreates the flag.

### D3: Topology pages stay as they are

- **Choice**: README and the documentation-tree header still point at the existing
  four Entro Connector topology pages. This change does not collapse them to three.
- **Reason**: Aligning page titles to Docker / Helm / SaaS Perimeter is a separate
  docs change.
- **Considered alternatives**: Rewrite in this change — rejected at grilling.

### D4: Glossary

- **Choice**: Connector requirement and Requirement evidence become superseded
  terms pointing at "a connector is always required" and Connector deployment for
  runtime topology. Setup method Notes drop the sentence that two setup methods
  must agree on connector requirement.
- **Reason**: Index specs must not keep using retired nouns.
- **Considered alternatives**: Keep terms for later prep — rejected; Worker Group
  can be named as a connection-detail field when that stage is in scope.

## Risks / Trade-offs

[Risk] Consumers of `integrations.json` still read the old keys → Mitigation:
breaking changelog; no in-repo consumers besides ingest tests.

[Trade-off] Operators still need to choose Docker vs Helm vs SaaS Perimeter →
Accepted: that choice stays in product-level connector docs, not the target index.

## Migration Plan

N/A — regenerate `documentation/integrations.json`. Acceptance:
`.venv/bin/python -m pytest` green and `openspec validate --all --json` all valid.

## Open Questions

None.
