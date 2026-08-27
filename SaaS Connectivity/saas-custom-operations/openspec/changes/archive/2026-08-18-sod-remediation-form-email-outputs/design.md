## Context

`custom:sod-remediation` persists four namespaced STRING attributes on the result source. Downstream ISC workflows (including the bundled Violation Response export) read those attributes after Get Accounts and feed them into Send Email. The keys still use situation-oriented names (`situation-summary`, `situation-header`, `owner-email`) even though their only consumer is the email step. Codegen derives `index.schema.ts` from `OperationSignature.output`; persist, README, and specs must stay aligned with those keys.

Stakeholders: connector authors, workflow authors consuming the result source, and anyone aggregating the SaaS Custom Operations source schema.

## Goals / Non-Goals

**Goals:**
- Persist `sod-remediation:form-url`, `sod-remediation:form-email-header`, `sod-remediation:form-email-body`, and `sod-remediation:form-email-recipient` as the only typed output fields
- Keep values, types, and HTML/plain-text semantics identical to today
- Update tests, README, codegen fixture, bundled workflow JSONPaths, and changelog

**Non-Goals:**
- Dual-write or alias of old keys
- Renaming internal TypeScript identifiers (`situationSummary`, `buildSituationHeader`, …)
- Changing form input `situationSummaryHtml` or the bundled form seed
- Changing `preventive-sod-check` or `access-sod-remediation` output keys

## Decisions

### D1: Hard rename vs dual-write
- **选择:** Hard rename. Old keys are not persisted.
- **理由:** User specified From→To replacement; dual-write would leave four extra schema attributes and delay cleanup.
- **已考虑 alternative:** Dual-write old+new — rejected. Alias layer in persist — rejected as framework complexity for a three-key rename.

### D2: Key naming
- **选择:** `form-email-body`, `form-email-header`, `form-email-recipient`; keep `form-url`.
- **理由:** Matches Send Email roles (body / subject / recipient list) and the existing `{slug}:{field}` namespacing convention.
- **已考虑 alternative:** `email-body` without `form-` prefix — rejected; user specified `form-email-*`. `situation-email-body` — rejected; drops the form-email grouping.

### D3: Internal TypeScript names
- **选择:** Keep builder and local variable names (`situationHeader`, `situationSummary`, `ownerEmail`).
- **理由:** Persist keys are the external contract; internal names still describe the situation HTML/header builders shared with form input.
- **已考虑 alternative:** Rename internals to `formEmailBody` etc. — out of scope; larger diff, no workflow benefit.

### D4: Form input vs persist
- **选择:** `situationSummaryHtml` formInput stays. Persist key for the email HTML becomes `form-email-body`.
- **理由:** Form DESCRIPTION interpolation is a separate contract from result-source attributes.
- **已考虑 alternative:** Rename formInput too — rejected; would force form-definition watermark / seed change.

### D5: Codegen and schema sidecar
- **选择:** Change `OperationSignature.output` keys; run `npm run codegen:schemas` so `index.schema.ts` regenerates. Do not hand-edit the sidecar except via codegen.
- **理由:** Sidecar is AUTO-GENERATED; tests and persist must match the signature.
- **已考虑 alternative:** Hand-edit sidecar only — rejected; next codegen would overwrite.

### D6: Bundled workflow
- **选择:** Update Send Email JSONPaths in `workflows/SOD Remediation - Violation Response.json`.
- **理由:** The export is the in-repo consumer of these keys; leaving it on old names would ship a broken example.
- **已考虑 alternative:** Docs-only note — rejected; the JSON is a runnable workflow artifact.

## Risks / Trade-offs

- [Risk] Deployed tenant workflows still read old keys → Mitigation: CHANGELOG breaking entry; update bundled export; README output table
- [Risk] Result-source schema retains old attributes after upgrade → Mitigation: persist-time reconciliation is add-only; old attributes become unused but harmless. Document that new invokes write only new keys
- [Trade-off] No dual-write compatibility window → Accept: smaller schema, one contract, explicit breaking change

## Migration Plan

1. Upgrade connector bundle.
2. Re-import or edit workflows: replace JSONPath attribute names (`situation-summary` → `form-email-body`, `situation-header` → `form-email-header`, `owner-email` → `form-email-recipient`).
3. Re-invoke `custom:sod-remediation` so new result accounts persist the new keys.
4. Rollback: revert connector version; workflows that already switched JSONPath must switch back.

## Open Questions

None — mapping and hard-rename decision approved.
