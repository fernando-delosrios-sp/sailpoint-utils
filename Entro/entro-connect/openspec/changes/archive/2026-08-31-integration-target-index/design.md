## Context

`documentation/integrations.json` is written by `write_integrations_index` from the hardcoded
`INTEGRATIONS` tuple in `integration_catalog.py`. There is no derivation step: the connector
values were typed in by hand, and `validate_integration_row` only checks internal shape, so
self-contradictory data validates clean.

The evidence base is the already-ingested `documentation/` tree. Every onboarding page states
its Add New Account navigation path, which makes the target directly readable — no re-crawl is
needed and GitBook is not called by this change.

Constraint from `openspec/specs/ubiquitous-language/spec.md`: integrations are named as in
Entro's onboarding catalog. The current rows use GitBook section names (`Remote File System`,
`SharePoint / OneDrive`, `Azure / Entra / M365`) rather than the tile labels the docs print
(`File Shares Scanning`, `Microsoft Ecosystem`), so naming is corrected as part of re-keying.

## Goals / Non-Goals

**Goals:**

- One row per Add New Account target, so no two rows can describe the same connection form
- Every non-`unknown` connector requirement traceable to an ingested page and a form label
- Setup methods and authentication methods preserved as row attributes when rows collapse
- Validation that fails on unproven or unresolvable claims

**Non-Goals:**

- Distilling integration-prep or connection-details content
- Changing ingest fetching, nav filtering, or the `documentation/` layout
- Modelling per-target permissions, scopes, or credential rotation
- Deriving rows automatically by parsing pages — the catalog stays curated, but now cited

## Decisions

### D1: Row key is (tile, target selection)

- **Choice**: `tile` holds the Add New Account tile label as the docs print it; `targetSelection`
  holds the explicit in-form target choice, or `null` when the tile leads straight to one form.
  The pair is the row's identity and MUST be unique.
- **Reason**: This is the level at which the connection form is determined, which is the level
  the connector requirement is a property of.
- **Considered alternatives**: One row per tile — rejected, because `GitHub Cloud - New`,
  `Cloud - Legacy`, and `Enterprise Server` have genuinely different forms under one tile.
  Keeping per-method rows with a grouping field — rejected, because it leaves the contradiction
  representable and relies on validation to catch it rather than making it unsayable.

### D2: Setup and authentication methods become row attributes

- **Choice**: `setupMethods` and `authenticationMethods` are lists of `{name, documentation}`.
  Collapsing rows moves their documentation paths into these lists rather than discarding them.
- **Reason**: AWS CloudFormation versus manual, and GCP Service Account key versus Workload
  Identity Federation, are real and separately documented; only their status as rows was wrong.
- **Considered alternatives**: Dropping the distinction — rejected, it loses page links that
  integration-prep will need.

### D3: `documentation` is a list, not a single path

- **Choice**: A row carries every ingested page that documents its target.
- **Reason**: Collapsed rows have several pages. The Microsoft Ecosystem row must still surface
  the SharePoint and Azure pages, or absorbing those rows would hide what the tile covers.

### D4: Requirement evidence shape

- **Choice**: `connectorEvidence` is `{page, basis, quote}`. `basis` is
  `worker-group-field-documented` when the page documents the field, or
  `complete-field-list-omits-worker-group` when the page gives a complete form field list with
  no Worker Group in it. `quote` carries the field label for the first basis and the field-list
  heading for the second.
- **Reason**: Naming the basis forces the distinction the old data collapsed — a documented
  absence versus an undocumented one.
- **Considered alternatives**: A bare page path — rejected, it does not record why the page
  settles the question, so the next author repeats the original mistake. Line numbers —
  rejected, they rot on every re-ingest.

### D5: `unknown` is the default and carries no evidence

- **Choice**: A target whose pages never settle the question is `unknown` with
  `connectorEvidence` absent. `not-required` requires basis `complete-field-list-omits-worker-group`.
- **Reason**: `unknown` is honest and visible; `not-required` was neither.

### D6: `connectorDeployments` and `connectorDocumentation` are removed from rows

- **Choice**: Drop both. The four topologies and their `entro-connector/` pages are documented
  once, outside the per-row data.
- **Reason**: Both were constant across every row, so they carried no per-row information.

### D7: Validation checks claims, not just shape

- **Choice**: `validate_integration_row` additionally fails when the `(tile, targetSelection)`
  pair repeats, when a non-`unknown` requirement has no `connectorEvidence`, when `basis` does
  not match the requirement value, and when any `documentation` or `page` path is not a file
  under `documentation/`.
- **Reason**: Path resolution is what turns a citation into evidence rather than a claim.

## Risks / Trade-offs

[Risk] Tile labels are printed inconsistently across pages (`AWS` in the nav path, `Amazon Web
Services` as the page title) → Mitigation: take the label from the Add New Account navigation
path, and record alternates only as extra `documentation` entries, not as new rows.

[Risk] Collapsing SharePoint / OneDrive into Microsoft Ecosystem could read as dropped coverage
→ Mitigation: D3 keeps the SharePoint pages on the row; the changelog states the merge explicitly.

[Trade-off] Row count drops and consumers must read `setupMethods` and `authenticationMethods`
to see what was previously a row → Accepted: there are no consumers yet, and this is the last
moment the shape is free to change.

[Trade-off] Several rows move to `unknown`, so the index answers fewer questions than before
→ Accepted: those answers were wrong, and `unknown` is what points a human at the gap.

## Migration Plan

N/A — no deployment changes. `documentation/integrations.json` is regenerated in place from the
updated catalog; acceptance is `python -m pytest` green plus `openspec validate --all --json`
all valid.

## Open Questions

None.
