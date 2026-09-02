## Context

`custom:access-model-sod-remediation-apply` currently calls `getFormInstanceById` → `getFormInstanceByKeyV1`. ISC documents that get as recipient-only. The connector loopback token is not the form recipient (access item owner), so live apply fails after form submit. `searchFormInstancesByTenantV1` lists tenant instances, filters on `formDefinitionId eq`, and returns the same `formInput` / `formData` / `state` / `recipients` payload apply already parses.

Stakeholders: workflow operators using the bundled Access Model SOD Remediation export; PAT used for loopback.

## Goals / Non-Goals

**Goals:**
- Load the submitted instance without a recipient-scoped get
- Require `formDefinitionId` so the list filter stays bounded
- Paginate until the matching `formInstanceId` is found
- Keep persist identity, correction semantics, and parse validation unchanged
- Bind the bundled workflow to `{{$.trigger.formDefinitionId}}`

**Non-Goals:**
- Removing `getFormInstanceById` from `src/isc/forms/`
- Passing `formInput` / `formData` through the workflow
- Changing catalog PATCH, audit line, or result-source schema
- Filtering the list by instance id on the server (API does not support it)

## Decisions

### D1: Input field `formDefinitionId`

- **Choice:** Required string `formDefinitionId` next to `formInstanceId`
- **Reason:** Matches Custom Forms filter and form-submitted trigger; user shorthand `formId` is ambiguous
- **Considered alternatives:** `formId` — rejected (not ISC spelling). Resolve definition by name inside apply — rejected (extra search; trigger already has the id)

### D2: List-and-pick, no get-by-id fallback

- **Choice:** Apply always uses paginated tenant list + client-side id match when it needs the instance
- **Reason:** Get-by-id is the failing call; fallback would hide the same 403
- **Considered alternatives:** Try get-by-id then list — rejected. List all tenant instances without definition filter — rejected (unbounded)

### D3: Pagination and early exit

- **Choice:** Page size 250, offset += page length, stop on match or short page. Missing id → `ConnectorError`
- **Reason:** Same pattern as policies/roles/accounts; list API has no instance-id filter
- **Considered alternatives:** Collect all pages then pick — rejected (unnecessary work). Default limit omitted — rejected (SDK default is unspecified)

### D4: Shared normalization

- **Choice:** New forms helper returns `NormalizedFormInstance` using the same map flattening as `getFormInstanceById`
- **Reason:** `parseFormInstance` stays unchanged
- **Considered alternatives:** Duplicate normalize in the operation — rejected (target-client boundary)

### D5: Idempotency still first

- **Choice:** `readPriorTerminalApplyOutputs` before any list call
- **Reason:** Avoid walking instances when apply already persisted
- **Considered alternatives:** Always list — rejected (waste)

### D6: Offline

- **Choice:** Require trimmed `formDefinitionId` on the signature; resolve fixtures by `formInstanceId` only; no live list
- **Reason:** Offline fixtures are already keyed by instance id
- **Considered alternatives:** Key fixtures by definition id — rejected (no extra coverage)

### D7: Auth and errors

- **Choice:** Same loopback token as today. List failures go through existing `callFormsApi` / `ConnectorError` formatting. Missing instance is a handler validation error, not a catalog PATCH
- **Reason:** Preserve current error surface for workflow Failed branches
- **Considered alternatives:** Treat empty list as skipped-already-clean — rejected (would hide operator mis-binding)

## Risks / Trade-offs

- [Risk] Tenants with many instances of the same definition walk many pages on a miss → Mitigation: keep-alive already runs; fail fast after last page; definition filter is required
- [Risk] Breaking invoke: existing workflows omit `formDefinitionId` → Mitigation: bundled JSON + README; validation error names the missing field
- [Trade-off] Extra ISC calls vs one get → Reason for acceptance: get is not authorized for the PAT
- [Trade-off] Keep unused get-by-id helper → Reason for acceptance: other callers / tests; out of scope to delete

## Migration Plan

1. Ship connector with required `formDefinitionId`.
2. Update Custom Command JSON in Access Model SOD - Remediation to pass `{{$.trigger.formDefinitionId}}`.
3. Operators who imported the old export must edit the invoke body (or re-import).
4. Rollback: revert connector and workflow together; old connector ignores extra input fields but new connector cannot run without `formDefinitionId`.
5. Persist/output schema unchanged — no result-source migration.

Acceptance: `npm test`, `npm run typecheck`; apply tests cover list filter, second-page pick, missing instance, skip-list on prior persist; workflow JSON contains `formDefinitionId`.

## Open Questions

None.
