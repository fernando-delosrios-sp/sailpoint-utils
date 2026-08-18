## Why

Roles and access profiles are often designed without systematic SoD review: a single catalog item can bundle entitlements from both sides of an enforced policy, creating toxic combinations for every assignee. `custom:sod-remediation` only reacts after ISC records an **identity violation**; it does not scan the access catalog proactively. Teams today manually audit roles/APs or run ad-hoc scripts. Packaging catalog SoD evaluation as `custom:access-sod-remediation` gives governance workflows a connector-native scan that launches policy-owner remediation forms — aligned with sod-remediation form patterns but scoped to catalog design.

## What Changes

- Add **`custom:access-sod-remediation`** — scans enabled roles and/or access profiles in scope, evaluates intrinsic entitlement conflicts against enforced SoD policies (via `policyQuery` parsing, not predict), and creates one remediation form per **(access item, policy)** hit targeted to the **policy owner**.
- Add ISC modules: **sod-policies** (list/get policies, parse `policyQuery`, resolve owner); extend **roles** and **access-profiles** with paginated enabled-item listing.
- Shared remediation form (ensure-from-seed) inspired by sod-remediation Correct flow — no action selector; submit `remediationSide` to choose Group A or B entitlement removal.
- **Parent/child persist model**: parent `requestId` carries scan rollup; each form persists to child identity `` `${requestId}:${accessItemId}:${policyId}` ``.

**Operation contract**
- Input: `formName` (required), `scope` (optional, default `"*"`), `searchIndices` (optional, default `['accessprofiles','roles']`), `policyScope` (optional, default `state eq "ENFORCED"`), standard `requestId`
- Parent output: `access-sod-remediation:access-items-scanned`, `access-sod-remediation:violations-found`, optional `access-sod-remediation:forms-skipped`
- Child output (per form): `access-sod-remediation:form-url`, `access-sod-remediation:access-item-id`, `access-sod-remediation:access-item-type`, `access-sod-remediation:access-item-name`, `access-sod-remediation:policy-id`, `access-sod-remediation:policy-name`, `access-sod-remediation:recipient-id`

**Explicit non-goals**
- SoD predict API or identity-context evaluation
- Mitigate / compensating controls
- Removing nested access profiles as a unit from roles (entitlement-level trim only)
- Substitute for ISC scheduled SoD certification jobs

## Capabilities

### New Capabilities

- `connector-operations/access-sod-remediation`: Register and specify `custom:access-sod-remediation` scan, evaluation, form launch, and parent/child persist behavior
- `target-client/sod-policies`: SoD policy list/get, `policyQuery` side parsing, structured criteria fallback, policy owner resolution

### Modified Capabilities

- `target-client`: Add `sod-policies` to ISC module layout; expose SodPolicies API on SDK context
- `target-client/roles`: Paginated listing of enabled roles with optional search filter
- `target-client/access-profiles`: Paginated listing of enabled access profiles with optional search filter

## Impact

- New: `src/operations/access-sod-remediation/`, form seed, offline fixtures, payloads, operation README
- New: `src/isc/sod-policies/` (policy list, get, query parser)
- Extend: `src/isc/roles/`, `src/isc/access-profiles/` (list helpers)
- Modify: `connector-spec.json` (codegen), root README, CHANGELOG
- Tests: policyQuery parser, violation detection, form idempotency, parent/child persist, offline invoke via `call:op`
- External: Sod Policies API (`GET /sod-policies/v1`, list); Roles/Access Profiles list APIs; Custom Forms API; appropriate PAT scopes
