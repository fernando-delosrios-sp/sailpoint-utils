## Why

Access-model SoD remediation forms capture policy-owner decisions, but nothing in the connector applies those decisions to the ISC catalog today. Workflows would need many awkward input fields or raw HTTP PATCH steps. A dedicated `custom:access-model-sod-remediation-apply` operation with a single `formInstanceId` input closes the loop after form submit, matching flat AP form presentation (detach whole APs from roles, not trim AP internals) and preparing auditable catalog hygiene without identity-level revoke.

## What Changes

- Add **`custom:access-model-sod-remediation-apply`** under `src/operations/access-model-sod-remediation-apply/`
- Add ISC helpers: **`getFormInstanceByKeyV1` wrapper**, **role patch** (detach access profiles, remove direct entitlements, append description), **access profile patch** (remove entitlements, append description)
- Reuse **`expandAccessItemEntitlements`** (or shared extraction) to map side entitlement ids → AP detach vs direct entitlement removal on roles

**Operation contract**
- Input: `formInstanceId` (required), standard invoke `requestId` (for logging only; persist key is `formInstanceId`)
- Output / persist on `{formInstanceId}`:
  - `access-model-sod-remediation-apply:status` — `applied` | `skipped-already-clean`
  - `access-model-sod-remediation-apply:access-item-id`, `access-model-sod-remediation-apply:access-item-type`
  - `access-model-sod-remediation-apply:removed-entitlement-ids` (`string[]`, optional)
  - `access-model-sod-remediation-apply:detached-access-profile-ids` (`string[]`, optional)
  - `access-model-sod-remediation-apply:description-appended` (optional audit snippet)

**Remediation semantics**
- **ROLE:** side entitlement via nested AP → detach AP from role; direct entitlement → remove from role entitlements
- **ACCESS_PROFILE:** remove side entitlement ids from the AP under review
- **Description:** append audit line on the corrected catalog item
- **Never** patch entitlement lists on nested APs when correcting a role

**Explicit non-goals**
- Identity violation revoke (`custom:sod-remediation` Manage Access path)
- Re-running scan or closing form instances
- Modifying shared AP definitions when correcting a role (only role composition changes)

## Capabilities

### New Capabilities

- `connector-operations/access-model-sod-remediation-apply`: Register and specify `custom:access-model-sod-remediation-apply` form fetch, validation, catalog patch, description audit, persist, and offline invoke

### Modified Capabilities

- `target-client/forms`: Add `getFormInstanceByKeyV1` read helper with normalized `formInput` / `formData` parsing
- `target-client/roles`: Add generic role patch helpers (detach access profiles, remove direct entitlements, append description) without operation orchestration
- `target-client/access-profiles`: Add generic access profile patch helper to remove entitlements and append description
- `connector-operations/access-model-sod-remediation`: Update form-submit downstream scenario to name `custom:access-model-sod-remediation-apply` and AP-detach semantics
- `ubiquitous-language`: Promote **access model SoD remediation apply** and related correction vocabulary

## Impact

- New: `src/operations/access-model-sod-remediation-apply/`, offline payload, operation README
- Extend: `src/isc/forms/`, `src/isc/roles/`, `src/isc/access-profiles/`
- Modify: `connector-spec.json` (codegen), `auto-registry.ts`, root README, CHANGELOG
- Tests: form parse, correction plan, role AP detach vs direct ent, AP access-item path, idempotency, offline invoke
- External: Custom Forms get instance; Roles/Access Profiles GET + PATCH; PAT scopes for role/AP read and update
