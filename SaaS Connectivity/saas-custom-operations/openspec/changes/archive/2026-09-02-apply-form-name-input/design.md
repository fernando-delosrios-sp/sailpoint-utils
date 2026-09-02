## Context

`custom:access-model-sod-remediation` ensures a shared form definition by `formName`. `custom:access-model-sod-remediation-apply` still requires `formDefinitionId` so it can list tenant instances. That UUID usually comes from `{{$.trigger.formDefinitionId}}`, which is easy to desync from the scan name and is tenant-specific in the bundled workflow.

Instance load stays list-and-pick (`searchFormInstancesByTenantV1` filtered by definition id). This change only changes how apply obtains that id: lookup by name, not caller-supplied UUID.

Stakeholders: operators of Access Model SOD Analysis + Remediation; loopback PAT.

## Goals / Non-Goals

**Goals:**
- Align apply input with scan: required `formName`
- Resolve name → definition id without creating or patching the definition
- Keep list-and-pick, persist identity, and catalog correction unchanged
- Bind the bundled Remediation invoke to the same `formName` string as Analysis

**Non-Goals:**
- Dual-support for `formDefinitionId` on apply input
- Calling `ensureFormDefinitionByName` from apply
- Changing the form-submitted trigger filter UUID
- Changing catalog PATCH, audit line, or result-source schema
- Changing `custom:sod-remediation`

## Decisions

### D1: Replace `formDefinitionId` with `formName`

- **Choice:** Required trimmed `formName`; drop `formDefinitionId` from `OperationSignature.input`
- **Reason:** One operator-facing name across scan and apply; trigger UUID is not the shared contract
- **Considered alternatives:** Accept both fields — rejected (two ways to bind, drift). Keep UUID and add optional name — rejected (does not align the required contract)

### D2: Lookup only, not ensure

- **Choice:** Search definitions with `name eq "<escaped formName>"` and take the first id. Empty results → `ConnectorError`. No get/patch/create of the definition on apply
- **Reason:** Scan owns seed ensure. Apply must not create a new empty definition or patch the seed when applying a completed instance
- **Considered alternatives:** Reuse `ensureFormDefinitionByName` — rejected (create/patch side effects). Get definition by id from trigger — rejected (this change removes that input)

### D3: Reuse list-and-pick after resolve

- **Choice:** After lookup, call existing `getFormInstanceByDefinitionAndId`. Still no `getFormInstanceByKeyV1` on apply
- **Reason:** Instance-list API still filters only by definition id; pagination and normalize already exist
- **Considered alternatives:** List instances by form name — rejected (API filter is definition id)

### D4: Forms helper boundary

- **Choice:** Add `findFormDefinitionIdByName` (or equivalent) in `src/isc/forms/` using the same OData escape and `callFormsApi` as ensure. Apply calls it; ensure may later share the search, but apply MUST NOT call ensure
- **Reason:** Target-client owns Custom Forms search; handler stays orchestration
- **Considered alternatives:** Inline search in the apply handler — rejected (duplicates ensure’s filter/escape)

### D5: Idempotency still first

- **Choice:** `readPriorTerminalApplyOutputs` before definition lookup and instance list
- **Reason:** Skip two ISC searches when apply already persisted for `{formInstanceId}`
- **Considered alternatives:** Always look up the name — rejected (waste)

### D6: Errors

- **Choice:** Blank `formName` → missing-field `ConnectorError` (no ISC calls). Missing definition → validation `ConnectorError` (no instance list, no PATCH). Search SDK failures stay `callFormsApi` / `ConnectorError`. Missing instance after list unchanged
- **Reason:** Same Failed-branch surface as today; name the field operators must fix
- **Considered alternatives:** Treat missing definition as skipped — rejected (hides mis-bound `formName`)

### D7: Offline and auth

- **Choice:** Require non-empty `formName`; resolve fixtures by `formInstanceId` only; no definition search and no instance list. Connected path uses the existing loopback token
- **Reason:** Offline fixtures are keyed by instance id; extra search adds no coverage
- **Considered alternatives:** Mock definition search in offline SDK — unnecessary if handler short-circuits like today’s list skip

### D8: Workflow

- **Choice:** Remediation Custom Command input `formName`: `Access Model SOD Remediation` (same as Analysis). Keep `formInstanceId` from the trigger. Leave trigger `formDefinitionId` filter as a tenant UUID with the existing import note
- **Reason:** ISC form-submitted trigger still filters by definition id; the connector invoke does not need that UUID
- **Considered alternatives:** Keep passing trigger definition id into the connector — rejected (this change’s purpose)

## Risks / Trade-offs

- [Risk] Apply `formName` differs from the definition that created the instance → list misses `formInstanceId` → Mitigation: README and bundled workflow use the same string as Analysis; error remains missing-instance
- [Risk] Breaking invoke: workflows still send `formDefinitionId` → Mitigation: CHANGELOG + validation names `formName`; bundled JSON updated together
- [Risk] Duplicate form names in a tenant → first search hit may be wrong → Mitigation: same risk as scan ensure; operators use a unique `formName`
- [Trade-off] Extra definition search vs passing UUID from trigger → Reason for acceptance: name is the stable operator contract; UUID is tenant-specific
- [Trade-off] Apply cannot self-heal a missing definition → Reason for acceptance: creating/patching on apply is the wrong lifecycle

## Migration Plan

1. Ship connector with required `formName` and no `formDefinitionId` on apply.
2. Update Access Model SOD - Remediation invoke to pass `formName` (same value as Analysis).
3. Operators with an older imported workflow must edit the Custom Command body (or re-import). Trigger filter UUID still needs tenant re-point after first scan.
4. Rollback: revert connector and workflow together. New connector rejects missing `formName`; old connector ignores unknown `formName` but required `formDefinitionId` would be gone from the new workflow.
5. Persist/output schema unchanged — no result-source migration.

Acceptance: `npm test`, `npm run typecheck`; apply tests cover lookup + list, missing name, missing definition, prior persist skips lookup; workflow JSON has `formName` not trigger `formDefinitionId` on the invoke.

## Open Questions

None.
