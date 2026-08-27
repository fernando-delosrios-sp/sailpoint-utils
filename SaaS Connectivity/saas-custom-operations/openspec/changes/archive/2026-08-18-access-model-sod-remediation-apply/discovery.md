## Scope

Add `custom:access-model-sod-remediation-apply` to apply a completed access-model SoD remediation form decision to the ISC catalog: detach nested access profiles from roles or remove direct role entitlements; remove entitlements from access-profile catalog items when the violated item is an AP; append an audit line to the access item description. Single required input: `formInstanceId`. Out of scope: identity access revocation (`custom:sod-remediation`), re-scan, patching nested AP entitlement definitions, form HTML changes (done in `access-model-sod-flat-ap-form`).

## Language

**Access model SoD remediation apply** (`promote`):
The custom operation `custom:access-model-sod-remediation-apply` that reads a completed access-model SoD remediation form instance and mutates the catalog access item to reflect the recipient's `remediationSide` decision.
_Avoid_: access model sod apply, sod correct (without access-model prefix)

**Catalog correction plan** (`draft`):
The resolved set of direct entitlement removals and access profile detachments derived from `formData.remediationSide`, `formInput.groupAIds` / `groupBIds`, and expanded role composition.
_Avoid_: remediation payload, patch plan

**Form instance correction input** (`draft`):
The sole operation input `formInstanceId` used to fetch launch-time `formInput` and submitted `formData` via Custom Forms API.
_Avoid_: passing through individual form fields in workflow input

## Decisions

**Context:** `custom:access-model-sod-remediation` creates forms; flat AP HTML (prior change) shows whole APs as removable units. Workflows need a connector operation after form submit with minimal JSONPath wiring.

**Q1 — Operation command name?**
→ Chosen: `custom:access-model-sod-remediation-apply`

**Q2 — Workflow input shape?**
→ Chosen: Required `formInstanceId` only; operation fetches instance via `getFormInstanceByKeyV1` and parses `formInput` + `formData` (also tolerate workflow `formInstanceInputs[].value` shape when present on fetched payload).

**Q3 — Role remediation semantics?**
→ Chosen: For each entitlement id on the selected side, if granted via nested AP on the role → detach whole AP from role (`accessProfiles` patch); if direct on role → remove from role `entitlements` patch. Never patch nested AP entitlement lists when correcting a role.

**Q4 — Access profile access-item violations?**
→ Chosen: When `accessItemType` is `ACCESS_PROFILE`, remove selected-side entitlement ids from that AP's entitlement list (the AP is the catalog item under review).

**Q5 — Description audit?**
→ Chosen: Append structured line to the corrected catalog item description (role or AP) including policy name, side, removed/detached items, form instance id, submitter, optional comments, timestamp.

**Q6 — Persist identity?**
→ Chosen: Persist operation output on result-source identity `{formInstanceId}` (not scan child `{requestId}:{accessItemId}:{policyId}`).

**Q7 — Idempotency?**
→ Chosen: If selected-side entitlements already absent and APs already detached → `skipped-already-clean` success, no error.

**Q8 — Offline?**
→ Chosen: Fixture map keyed by `formInstanceId` with deterministic patch simulation; no live PATCH in testMode/offline.

## Open questions

None.

## Scenarios discussed

- Completed form with `remediationSide=groupA`, role with direct Buyer + nested AP with payment_issue on B: remove Buyer from role; leave AP when A selected.
- Same role, `remediationSide=groupB`: detach AP from role; do not patch AP internal entitlements.
- ACCESS_PROFILE violation: remove side entitlements from the AP definition directly.
- Form state ASSIGNED or IN_PROGRESS: fail with clear error.
- Second invoke after successful apply: skipped-already-clean.
- Missing `groupAIds` JSON or invalid `remediationSide`: validation failure before PATCH.
- Offline `call:op` with canned form instance and catalog fixtures.
