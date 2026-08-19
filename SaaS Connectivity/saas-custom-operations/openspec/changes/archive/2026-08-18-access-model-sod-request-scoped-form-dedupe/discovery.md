## Scope

**In:** Scope access-model SoD remediation form-instance dedupe to the scan's `requestId` (parent request). Store `parentRequestId` on new form instances; skip creation only when an ASSIGNED instance already exists for the same form definition, `parentRequestId`, `accessItemId`, and `policyId`.

**Out:** Changes to `custom:access-model-sod-remediation-apply`, tenant-wide dedupe removal for other operations, workflow orchestration changes, or backfilling `parentRequestId` on legacy instances.

## Language

**parent request id** (`promote`):
The `requestId` supplied on a `custom:access-model-sod-remediation` invoke. It scopes child persist identities and, after this change, pending-form dedupe for that scan run.
_Avoid_: parentRequest, scanId (unless referring to the invoke input field name)

**pending remediation form instance** (`draft`):
A standalone form instance in `ASSIGNED` state awaiting policy-owner submission for access-model SoD remediation.
_Avoid_: open form, draft form

**request-scoped form dedupe** (`draft`):
Skip launching a remediation form when an ASSIGNED instance already exists for the same form definition, parent request id, access item, and policy — not tenant-wide across unrelated scans.
_Avoid_: global dedupe, tenant dedupe

## Decisions

**Context:** Today `hasAssignedRemediationInstance` matches any ASSIGNED instance tenant-wide on `accessItemId` + `policyId`. A new scan with a different `requestId` still skips form creation if an older pending form exists from a prior scan.

**Q1 — What identifies the parent scan on the form instance?**
→ Add declared `formInput.parentRequestId` (STRING, no UI element), set to `ctx.requestId` at launch.

**Q2 — What states count as "pending"?**
→ `ASSIGNED` only (unchanged). Submitted/completed instances do not block new launches.

**Q3 — Dedupe key?**
→ `{parentRequestId}:{accessItemId}:{policyId}` within the remediation form definition.

**Q4 — Legacy instances without `parentRequestId`?**
→ Do not match request-scoped dedupe (no backfill). They neither block nor satisfy dedupe for new scans.

**Q5 — Search strategy?**
→ Keep one `searchFormInstancesByTenantV1` per scan (by `formDefinitionId`); filter client-side by state and `formInput` fields including `parentRequestId`.

## Open questions

None — scope locked by user request.

## Scenarios discussed

- **Same scan re-invoked:** Same `requestId`, same violation → skip (increment `forms-skipped`).
- **New scan, old pending form from prior run:** Different `requestId`, ASSIGNED instance exists without matching `parentRequestId` or with different `parentRequestId` → create new form (behavior change from today).
- **Same scan, violation resolved then re-detected:** Prior instance no longer ASSIGNED → create form again.
- **Offline invoke:** Dedupe check remains bypassed (unchanged).
- **Form seed fingerprint:** Adding `parentRequestId` to declared `formInput` changes seed fingerprint; tenants need new `formName` or accept ensure-by-name behavior per existing migration pattern.
