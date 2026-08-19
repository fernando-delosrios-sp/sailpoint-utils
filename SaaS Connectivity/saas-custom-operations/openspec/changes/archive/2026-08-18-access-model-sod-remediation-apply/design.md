## Context

Phase 1 (`access-model-sod-flat-ap-form`, archived) flattened access-model SoD form group columns so nested access profiles appear as single removable rows. Phase 2 applies the recipient's `remediationSide` choice to the catalog. The scan operation (`custom:access-model-sod-remediation`) already launches forms with entitlement-based `groupAIds` / `groupBIds` in `formInput`; the correct operation interprets those ids at apply time.

## Goals / Non-Goals

**Goals:**
- Register `custom:access-model-sod-remediation-apply` with `formInstanceId`-only input
- Fetch completed form instance, validate, build catalog correction plan
- PATCH role or access profile per semantics below; append description audit
- Persist result on `{formInstanceId}`; support offline invoke

**Non-Goals:**
- Workflow input pass-through of form fields
- Patching nested AP entitlement definitions when correcting a role
- Identity access revocation or SoD violation APIs
- Form instance state transitions beyond read validation

## Decisions

### D1: Single input `formInstanceId`

- **Choice:** Operation input requires only `formInstanceId`; all context from fetched instance
- **Reason:** Minimize workflow JSONPath wiring after Wait for Form / trigger
- **Considered alternatives:** Flattened form fields in input — rejected (awkward in workflows)

### D2: Form instance parsing

- **Choice:** Normalize `formInput` and `formData` from API flat maps; if instance exposes `formInstanceInputs` array with `{ id, value }` objects, flatten to string map before validation
- **Reason:** Support both SDK response and workflow-enriched payloads
- **Considered alternatives:** Require workflows to pre-normalize — rejected

### D3: Validation gates

- **Choice:** Require `state === COMPLETED`; require `formData.remediationSide` in `{ groupA, groupB }`; require launch keys `accessItemId`, `accessItemType`, `policyId`, `policyName`, `groupAIds`, `groupBIds` (JSON strings)
- **Reason:** Fail fast before mutating catalog
- **Considered alternatives:** Accept SUBMITTED — rejected (COMPLETED is stable contract)

### D4: Correction plan for roles

- **Choice:** Expand access item; for each id in selected side's entitlement list, if id appears under a nested profile bundle → queue profile id for detach; else queue entitlement id for direct removal from role
- **Reason:** Matches flat AP form semantics and avoids shared AP mutation
- **Considered alternatives:** Patch AP entitlements — rejected per product decision

### D5: Correction plan for access profiles

- **Choice:** Remove selected-side entitlement ids from the access profile's entitlement list via `patchAccessProfileV1`
- **Reason:** Access item under review is the AP itself

### D6: JSON Patch strategy

- **Choice:** GET current role/AP; compute filtered `entitlements` and `accessProfiles` arrays; PATCH with `replace` on `/entitlements`, `/accessProfiles`, and `/description` as needed (single patch request per object)
- **Reason:** Safer than index-based remove when array order unknown
- **Considered alternatives:** Multiple remove ops by index — rejected (fragile)

### D7: Description append format

- **Choice:** Prefix line `[SOD remediation {ISO8601}] Policy "{policyName}" ({policyId}): …` listing detached APs (with offending entitlement names) and removed direct entitlements; note form instance id and submitter when available; append comments when non-empty
- **Reason:** Human-readable audit without overwriting existing description
- **Considered alternatives:** Replace description — rejected

### D8: Persist and invoke response

- **Choice:** `ctx.persist(formInstanceId, outputs)` and mirror key fields on `ctx.res.send({ status: 'success', ... })`
- **Reason:** Workflow can read invoke response or Get Accounts on form instance id
- **Considered alternatives:** Persist on scan child identity — rejected (requires extra workflow input)

### D9: Idempotent re-invoke

- **Choice:** When plan is empty (side entitlements already gone / APs already detached) → success with `access-model-sod-remediation-apply:status` `skipped-already-clean`, skip PATCH
- **Reason:** Safe workflow retries

### D10: Module layout

- **Choice:** `src/operations/access-model-sod-remediation-apply/` with `parse-form-instance.ts`, `build-correction-plan.ts`, `apply-correction.ts`, `description-audit.ts`, `offline-data.ts`; ISC patch helpers in `src/isc/roles/` and `src/isc/access-profiles/`; form fetch in `src/isc/forms/`
- **Reason:** Match existing operation + target-client boundaries

## Risks / Trade-offs

- [Risk] PATCH requires elevated PAT scopes → Mitigation: document ROLE_ADMIN / AP admin scopes in operation README
- [Risk] Role GET/PATCH race if catalog edited concurrently → Mitigation: accept last-write-wins; document operational guidance
- [Trade-off] Description grows unbounded with repeated corrections → Accepted for v1; truncation deferred

## Migration Plan

1. Deploy connector with new command registered in `connector-spec.json`
2. After access-model SoD form submit workflow step, invoke `custom:access-model-sod-remediation-apply` with `formInstanceId` from trigger
3. Read `access-model-sod-remediation-apply:status` from invoke response or persisted account
4. Rollback: remove workflow invoke step; revert connector

## Open Questions

None.
